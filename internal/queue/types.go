package queue

type Job struct {
	Bucket       string `json:"bucket"`
	Key          string `json:"key"`
	OutputBucket string `json:"output_bucket"`
	OutputKey    string `json:"output_key"`
	Width        int    `json:"width,omitempty"`
	Height       int    `json:"height,omitempty"`
	Format       string `json:"format,omitempty"`
}
