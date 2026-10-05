"""Regenerate every non-city content file (does NOT touch cities.json or story.json)."""
import gen_core, gen_live, gen_happenings, gen_progress, gen_ui

for mod in (gen_core, gen_live, gen_happenings, gen_progress, gen_ui):
    mod.main()
