// SPDX-License-Identifier: Unlicense OR MIT

package app

import (
	"testing"

	"gioui.org/io/event"
	"gioui.org/widget"
)

type configTestDriver struct {
	driver
}

func newConfigTestWindow() *Window {
	w := &Window{driver: new(configTestDriver)}
	w.decorations.Decorations = new(widget.Decorations)
	return w
}

func TestConfigEventHiddenIsDelivered(t *testing.T) {
	w := newConfigTestWindow()
	if !w.processEvent(ConfigEvent{Config: Config{Hidden: true}}) {
		t.Fatal("a ConfigEvent that hides the window was not reported as handled")
	}
	e, ok := w.nextEvent()
	if !ok {
		t.Fatal("no event after hiding the window")
	}
	cfg, ok := e.(ConfigEvent)
	if !ok {
		t.Fatalf("got %T, want ConfigEvent", e)
	}
	if !cfg.Config.Hidden {
		t.Error("ConfigEvent does not report the window as hidden")
	}
	if w.processEvent(ConfigEvent{Config: Config{Hidden: true}}) {
		t.Error("a ConfigEvent without a change was reported as handled")
	}
	w.nextEvent()
	if !w.processEvent(ConfigEvent{Config: Config{}}) {
		t.Fatal("a ConfigEvent that shows the window was not reported as handled")
	}
	e, _ = w.nextEvent()
	if cfg, ok := e.(ConfigEvent); !ok || cfg.Config.Hidden {
		t.Errorf("got %#v, want a ConfigEvent of a visible window", e)
	}
}

// TestFlushEventsWaitsForClient verifies that a driver's FlushEvents returns
// only after the client has handled the event and asked for the next one.
// Drivers rely on it to deliver an event before the native callback returns.
func TestFlushEventsWaitsForClient(t *testing.T) {
	w := newConfigTestWindow()
	loop := newEventLoop(&callbacks{w: w}, func() {})
	flushed := make(chan struct{})
	go func() {
		w.processEvent(ConfigEvent{Config: Config{Hidden: true}})
		loop.FlushEvents()
		close(flushed)
	}()
	e := loop.Event()
	if cfg, ok := e.(ConfigEvent); !ok || !cfg.Config.Hidden {
		t.Fatalf("got %#v, want a ConfigEvent of a hidden window", e)
	}
	// The client is still handling the event.
	select {
	case <-flushed:
		t.Fatal("FlushEvents returned before the client handled the event")
	default:
	}
	// Asking for the next event receives the flush marker, as Event does
	// internally, which completes the delivery.
	if e := <-loop.events; !isFlushEvent(e) {
		t.Fatalf("got %#v, want the flush marker", e)
	}
	<-flushed
}

func isFlushEvent(e event.Event) bool {
	_, ok := e.(flushEvent)
	return ok
}
