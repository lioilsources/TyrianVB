package grokimage

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
)

func TestClientGenerateSuccess(t *testing.T) {
	fakeImage := base64.StdEncoding.EncodeToString([]byte("fake-jpg-data"))

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer test-key" {
			t.Error("missing or wrong Authorization header")
		}
		if r.Header.Get("Content-Type") != "application/json" {
			t.Error("missing Content-Type header")
		}

		var req GenerateRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if req.Model != "grok-imagine-image" {
			t.Errorf("expected model grok-imagine-image, got %s", req.Model)
		}
		if req.N != 4 {
			t.Errorf("expected N=4, got %d", req.N)
		}

		resp := GenerateResponse{
			Data: []ImageData{
				{B64JSON: fakeImage, RevisedPrompt: "revised"},
			},
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	}))
	defer server.Close()

	client := NewClient("test-key", WithAPIURL(server.URL), WithMaxRetries(0))
	resp, err := client.Generate(context.Background(), GenerateRequest{
		Model:          "grok-imagine-image",
		Prompt:         "test prompt",
		N:              4,
		AspectRatio:    "1:1",
		Resolution:     "1k",
		ResponseFormat: "b64_json",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(resp.Data) != 1 {
		t.Fatalf("expected 1 image, got %d", len(resp.Data))
	}

	imgBytes, err := resp.Data[0].Bytes()
	if err != nil {
		t.Fatalf("decode image: %v", err)
	}
	if string(imgBytes) != "fake-jpg-data" {
		t.Error("decoded image data mismatch")
	}
}

func TestClientRetryOn500(t *testing.T) {
	var calls atomic.Int32
	fakeImage := base64.StdEncoding.EncodeToString([]byte("ok"))

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		n := calls.Add(1)
		if n <= 2 {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("server error"))
			return
		}
		resp := GenerateResponse{Data: []ImageData{{B64JSON: fakeImage}}}
		json.NewEncoder(w).Encode(resp)
	}))
	defer server.Close()

	client := NewClient("test-key", WithAPIURL(server.URL), WithMaxRetries(3))
	resp, err := client.Generate(context.Background(), GenerateRequest{
		Model:          "grok-imagine-image",
		Prompt:         "test",
		N:              1,
		ResponseFormat: "b64_json",
	})
	if err != nil {
		t.Fatalf("expected success after retries, got: %v", err)
	}
	if len(resp.Data) != 1 {
		t.Error("expected 1 image after retry")
	}
	if calls.Load() != 3 {
		t.Errorf("expected 3 calls (2 failures + 1 success), got %d", calls.Load())
	}
}

func TestClientFatalOn401(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte("invalid api key"))
	}))
	defer server.Close()

	client := NewClient("bad-key", WithAPIURL(server.URL), WithMaxRetries(3))
	_, err := client.Generate(context.Background(), GenerateRequest{
		Model:          "grok-imagine-image",
		Prompt:         "test",
		N:              1,
		ResponseFormat: "b64_json",
	})
	if err == nil {
		t.Fatal("expected error for 401")
	}
}

func TestClientContentRejected(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("content policy violation"))
	}))
	defer server.Close()

	client := NewClient("test-key", WithAPIURL(server.URL), WithMaxRetries(3))
	_, err := client.Generate(context.Background(), GenerateRequest{
		Model:          "grok-imagine-image",
		Prompt:         "bad content",
		N:              1,
		ResponseFormat: "b64_json",
	})
	if err == nil {
		t.Fatal("expected error for content rejection")
	}
}

func TestClientModelFallback(t *testing.T) {
	var models []string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var req GenerateRequest
		json.NewDecoder(r.Body).Decode(&req)
		models = append(models, req.Model)

		if req.Model == "grok-imagine-image" {
			w.WriteHeader(http.StatusNotFound)
			w.Write([]byte("model not found"))
			return
		}

		fakeImage := base64.StdEncoding.EncodeToString([]byte("ok"))
		resp := GenerateResponse{Data: []ImageData{{B64JSON: fakeImage}}}
		json.NewEncoder(w).Encode(resp)
	}))
	defer server.Close()

	client := NewClient("test-key", WithAPIURL(server.URL), WithMaxRetries(3))
	resp, err := client.Generate(context.Background(), GenerateRequest{
		Model:          "grok-imagine-image",
		Prompt:         "test",
		N:              1,
		ResponseFormat: "b64_json",
	})
	if err != nil {
		t.Fatalf("expected success with fallback, got: %v", err)
	}
	if len(resp.Data) != 1 {
		t.Error("expected 1 image")
	}
	if len(models) < 2 || models[1] != "grok-2-image" {
		t.Errorf("expected fallback to grok-2-image, got models: %v", models)
	}
}
