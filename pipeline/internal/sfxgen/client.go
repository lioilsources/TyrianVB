package sfxgen

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"time"
)

// Client wraps the ElevenLabs Sound Effects API.
type Client struct {
	apiKey  string
	httpCli *http.Client
}

// NewClient creates a new ElevenLabs SFX client.
func NewClient(apiKey string) *Client {
	return &Client{
		apiKey: apiKey,
		httpCli: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// GenerateRequest describes the sound to generate.
type GenerateRequest struct {
	Text            string  `json:"text"`
	DurationSeconds float64 `json:"duration_seconds"`
	PromptInfluence float64 `json:"prompt_influence"`
}

const apiURL = "https://api.elevenlabs.io/v1/sound-generation"

// Generate calls the ElevenLabs Sound Effects API and returns raw MP3 bytes.
// Retries on 429 with exponential backoff (up to 3 attempts).
func (c *Client) Generate(ctx context.Context, req GenerateRequest) ([]byte, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	var lastErr error
	for attempt := 0; attempt < 3; attempt++ {
		if attempt > 0 {
			delay := time.Duration(math.Pow(2, float64(attempt))) * time.Second
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(delay):
			}
		}

		httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, bytes.NewReader(body))
		if err != nil {
			return nil, fmt.Errorf("create request: %w", err)
		}
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("xi-api-key", c.apiKey)

		resp, err := c.httpCli.Do(httpReq)
		if err != nil {
			lastErr = fmt.Errorf("http request: %w", err)
			continue
		}

		data, readErr := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode == http.StatusTooManyRequests {
			lastErr = fmt.Errorf("rate limited (429)")
			continue
		}

		if resp.StatusCode != http.StatusOK {
			lastErr = fmt.Errorf("API error %d: %s", resp.StatusCode, string(data))
			continue
		}

		if readErr != nil {
			lastErr = fmt.Errorf("read response: %w", readErr)
			continue
		}

		return data, nil
	}

	return nil, fmt.Errorf("all attempts failed: %w", lastErr)
}
