// SPDX-License-Identifier: Unlicense OR MIT

package app

import (
	"image/color"
	"testing"

	"gioui.org/unit"
	"gioui.org/widget"
	"gioui.org/widget/material"
)

func TestDecorationColors(t *testing.T) {
	bg := color.NRGBA{R: 0x20, G: 0x22, B: 0x25, A: 0xff}
	fg := color.NRGBA{R: 0xe0, G: 0xe0, B: 0xe0, A: 0xff}

	var cnf Config
	cnf.apply(unit.Metric{}, []Option{Title("x")})
	if cnf.decoColors != nil {
		t.Fatal("an option other than DecorationColors set the colors")
	}
	cnf.apply(unit.Metric{}, []Option{DecorationColors(bg, fg)})
	if cnf.decoColors == nil || *cnf.decoColors != (decorationColors{bg: bg, fg: fg}) {
		t.Fatalf("DecorationColors set %v", cnf.decoColors)
	}

	th := material.NewTheme()
	def := material.Decorations(th, new(widget.Decorations), 0, "title")
	style := cnf.decoColors.apply(def)
	if style.Background != bg || style.Foreground != fg || style.Title.Color != fg {
		t.Errorf("colors not applied: background %v, foreground %v, title %v", style.Background, style.Foreground, style.Title.Color)
	}

	// A zero color keeps the default of the theme.
	style = decorationColors{fg: fg}.apply(def)
	if style.Background != def.Background || style.Foreground != fg {
		t.Errorf("zero background replaced the default: %v", style.Background)
	}
	if style = (decorationColors{}).apply(def); style.Background != def.Background || style.Foreground != def.Foreground || style.Title.Color != def.Title.Color {
		t.Error("zero colors changed the default style")
	}
}
