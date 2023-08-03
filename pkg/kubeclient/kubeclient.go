package kubeclient

import (
	"io"
	"net/http"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func init() {
	// "v1 ComponentStatus is deprecated in v1.19+",
	rest.SetDefaultWarningHandler(
		rest.NewWarningWriter(io.Discard, rest.WarningWriterOptions{
			Deduplicate: true,
		}))
}

//TODO: prep cache

func New(c rest.Interface) *kubernetes.Clientset {
	return kubernetes.New(c)
}

func NewForConfig(c *rest.Config) (*kubernetes.Clientset, error) {
	return kubernetes.NewForConfig(c)
}

func NewForConfigAndClient(c *rest.Config, httpclient *http.Client) (*kubernetes.Clientset, error) {
	return kubernetes.NewForConfigAndClient(c, httpclient)
}

func NewForConfigOrDie(c *rest.Config) *kubernetes.Clientset {
	return kubernetes.NewForConfigOrDie(c)
}
