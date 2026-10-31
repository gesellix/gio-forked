// SPDX-License-Identifier: Unlicense OR MIT

package app

import (
	"testing"
	"time"
)

// reentrantDriver delivers events from Invalidate, like the macOS and iOS
// drivers do when Invalidate is called on the main thread.
type reentrantDriver struct {
	driver
	w       *Window
	invalid int
}

func (d *reentrantDriver) Invalidate() {
	d.invalid++
	d.w.nextEvent()
}

func TestInvalidateDeliversEvents(t *testing.T) {
	w := new(Window)
	d := &reentrantDriver{w: w}
	w.driver = d
	w.mayInvalidate = true
	done := make(chan struct{})
	go func() {
		defer close(done)
		w.Invalidate()
	}()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("Invalidate deadlocked delivering events")
	}
	if d.invalid != 1 {
		t.Errorf("driver invalidated %d times, want 1", d.invalid)
	}
	// nextEvent found no event and allows the next invalidation.
	if !w.mayInvalidate {
		t.Error("mayInvalidate not reset by nextEvent")
	}
}
