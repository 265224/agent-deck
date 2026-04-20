#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import sys


def fail(message: str) -> None:
    raise SystemExit(f"Smoke failed: {message}")


def load_json(path: pathlib.Path) -> dict:
    if not path.exists():
        fail(f"missing file at {path}")
    return json.loads(path.read_text())


def require_path(path: pathlib.Path, context: str) -> None:
    if not path.exists():
        fail(f"missing {context} at {path}")


def find_overlay_window(report: dict) -> dict:
    windows = report.get("windows") or []
    overlay = next((window for window in windows if window.get("kind") == "overlay"), None)
    if overlay is None:
        fail("report is missing an overlay window artifact")
    return overlay


def collect_ax_strings(node: dict, labels: set[str], button_labels: set[str], text_values: set[str]) -> None:
    label = node.get("label")
    if isinstance(label, str) and label:
        labels.add(label)
        role = (node.get("role") or "").lower()
        if "button" in role:
            button_labels.add(label)

    value = node.get("value")
    if isinstance(value, str) and value:
        text_values.add(value)

    for child in node.get("children") or []:
        collect_ax_strings(child, labels, button_labels, text_values)


def require_frame_between(frame: dict, *, width: tuple[float, float], height: tuple[float, float], context: str) -> None:
    frame_width = frame.get("width")
    frame_height = frame.get("height")
    if not isinstance(frame_width, (int, float)) or not isinstance(frame_height, (int, float)):
        fail(f"{context} is missing width/height")

    min_width, max_width = width
    min_height, max_height = height
    if not (min_width <= frame_width <= max_width):
        fail(f"{context} width {frame_width} is outside expected range {width}")
    if not (min_height <= frame_height <= max_height):
        fail(f"{context} height {frame_height} is outside expected range {height}")


def require_overlay_frame_between(
    report: dict,
    frame: dict,
    *,
    notch_width: tuple[float, float],
    notch_height: tuple[float, float],
    context: str,
) -> None:
    overlay_mode = (report.get("overlay") or {}).get("mode")
    if overlay_mode == "Desktop pet":
        if report.get("notchStatus") == "closed":
            width = (150, 170)
            height = (205, 225)
        else:
            width = (500, 540)
            height = (600, 660)
    else:
        width = notch_width
        height = notch_height

    require_frame_between(frame, width=width, height=height, context=context)


def assert_contains_any(haystack: set[str], needles: list[str], context: str) -> None:
    if not any(needle in item for item in haystack for needle in needles):
        fail(f"{context} is missing any of {needles}")


def validate_runtime(report_path: pathlib.Path, report: dict) -> None:
    runtime = report.get("runtime")
    if not isinstance(runtime, dict):
        fail("report is missing runtime observability artifacts")

    timeline_rel_path = runtime.get("timelinePath")
    log_rel_path = runtime.get("logPath")
    if not isinstance(timeline_rel_path, str) or not timeline_rel_path:
        fail("runtime timelinePath is missing")
    if not isinstance(log_rel_path, str) or not log_rel_path:
        fail("runtime logPath is missing")

    timeline_path = report_path.parent / timeline_rel_path
    log_path = report_path.parent / log_rel_path
    require_path(timeline_path, "runtime timeline")
    require_path(log_path, "runtime log")

    timeline = json.loads(timeline_path.read_text())
    if not isinstance(timeline, list) or not timeline:
        fail("runtime timeline is empty")

    event_count = runtime.get("eventCount")
    if event_count != len(timeline):
        fail(f"runtime eventCount {event_count!r} does not match timeline length {len(timeline)}")

    if runtime.get("launchCompleted") is not True:
        fail("runtime launchCompleted is false")

    milestones = runtime.get("milestones")
    if not isinstance(milestones, list) or not milestones:
        fail("runtime milestones are missing")

    milestone_names = [milestone.get("name") for milestone in milestones if isinstance(milestone, dict)]
    required_names = {
        "applicationDidFinishLaunching",
        "bootstrapStarted",
        "modelStarted",
        "controlCenterConfigured",
        "bootstrapCompleted",
        "captureScheduled",
        "captureStarted",
    }
    missing = sorted(required_names - set(name for name in milestone_names if isinstance(name, str)))
    if missing:
        fail(f"runtime milestones are missing {missing}")

    if report.get("presentOverlay") and "overlayPresented" not in milestone_names:
        fail("runtime milestones are missing overlayPresented for an overlay-present run")

    if report.get("startedBridge") is False and "bridgeSkipped" not in milestone_names:
        fail("runtime milestones are missing bridgeSkipped for a deterministic run")

    timings = runtime.get("timings")
    if not isinstance(timings, dict):
        fail("runtime timings are missing")

    bootstrap_seconds = timings.get("bootstrapSeconds")
    if not isinstance(bootstrap_seconds, (int, float)) or bootstrap_seconds <= 0 or bootstrap_seconds > 3.5:
        fail(f"bootstrapSeconds {bootstrap_seconds!r} is outside the expected range")

    capture_scheduled_seconds = timings.get("captureScheduledSeconds")
    if not isinstance(capture_scheduled_seconds, (int, float)) or capture_scheduled_seconds <= 0 or capture_scheduled_seconds > 2.5:
        fail(f"captureScheduledSeconds {capture_scheduled_seconds!r} is outside the expected range")

    capture_started_seconds = timings.get("captureStartedSeconds")
    if not isinstance(capture_started_seconds, (int, float)) or capture_started_seconds < capture_scheduled_seconds:
        fail(
            "captureStartedSeconds is missing or occurs before captureScheduledSeconds"
        )

    if report.get("presentOverlay"):
        overlay_presented_seconds = timings.get("overlayPresentedSeconds")
        if not isinstance(overlay_presented_seconds, (int, float)) or overlay_presented_seconds <= 0 or overlay_presented_seconds > 2.5:
            fail(f"overlayPresentedSeconds {overlay_presented_seconds!r} is outside the expected range")

    launch_to_capture_seconds = timings.get("launchToCaptureSeconds")
    report_launch_to_capture_seconds = report.get("launchToCaptureSeconds")
    if not isinstance(launch_to_capture_seconds, (int, float)) or launch_to_capture_seconds <= 0 or launch_to_capture_seconds > 5.0:
        fail(f"launchToCaptureSeconds {launch_to_capture_seconds!r} is outside the expected range")
    if report_launch_to_capture_seconds != launch_to_capture_seconds:
        fail("runtime launchToCaptureSeconds does not match report launchToCaptureSeconds")

    if not isinstance(runtime.get("latestMessage"), str) or not runtime.get("latestMessage"):
        fail("runtime latestMessage is missing")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: validate-harness-artifacts.py <report.json>")

    report_path = pathlib.Path(sys.argv[1])
    report = load_json(report_path)
    validate_runtime(report_path, report)
    overlay = find_overlay_window(report)

    accessibility_path = overlay.get("accessibilityPath")
    if not accessibility_path:
        fail("overlay window is missing accessibilityPath")

    ax_path = report_path.parent / accessibility_path
    ax_tree = load_json(ax_path)

    labels: set[str] = set()
    button_labels: set[str] = set()
    text_values: set[str] = set()
    collect_ax_strings(ax_tree, labels, button_labels, text_values)

    summary = overlay.get("accessibilitySummary") or {}
    labels.update(summary.get("labels") or [])
    button_labels.update(summary.get("buttonLabels") or [])
    text_values.update(summary.get("textValues") or [])

    scenario = report.get("scenario")
    if not isinstance(scenario, str) or not scenario:
        fail("report is missing scenario")

    island_surface = report.get("islandSurface") or ""
    notch_status = report.get("notchStatus")
    overlay_mode = (report.get("overlay") or {}).get("mode")
    overlay_frame = overlay.get("frame") or {}

    if scenario == "emptyClosed":
        if notch_status != "closed":
            fail(f"expected empty closed notch, got {notch_status!r}")
        if island_surface != "sessionList":
            fail(f"expected empty closed scenario to use sessionList surface, got {island_surface!r}")
        require_overlay_frame_between(
            report,
            overlay_frame,
            notch_width=(660, 760),
            notch_height=(120, 180),
            context="empty closed overlay frame",
        )
        if report.get("liveSessionCount") != 0:
            fail("empty closed scenario should not contain live sessions")

    elif scenario == "closed":
        if notch_status != "closed":
            fail(f"expected closed notch, got {notch_status!r}")
        if island_surface != "sessionList":
            fail(f"expected closed scenario to use sessionList surface, got {island_surface!r}")
        require_overlay_frame_between(
            report,
            overlay_frame,
            notch_width=(660, 760),
            notch_height=(450, 540),
            context="closed overlay frame",
        )
        live_session_count = report.get("liveSessionCount")
        count_sources = labels if overlay_mode == "Desktop pet" else text_values
        if not any(str(live_session_count) in value for value in count_sources):
            fail("closed scenario is missing the live session count value")

    elif scenario == "sessionList":
        if notch_status != "opened":
            fail(f"expected opened notch for sessionList, got {notch_status!r}")
        if island_surface != "sessionList":
            fail(f"expected sessionList surface, got {island_surface!r}")
        require_overlay_frame_between(
            report,
            overlay_frame,
            notch_width=(680, 780),
            notch_height=(360, 500),
            context="sessionList overlay frame",
        )
        assert_contains_any(text_values, ["Codex"], "sessionList text values")
        assert_contains_any(text_values, ["Ghostty"], "sessionList text values")

    elif scenario == "approvalCard":
        if notch_status != "opened":
            fail(f"expected opened notch for approvalCard, got {notch_status!r}")
        if not island_surface.startswith("sessionList:actionable("):
            fail(f"expected approvalCard surface, got {island_surface!r}")
        require_overlay_frame_between(
            report,
            overlay_frame,
            notch_width=(660, 760),
            notch_height=(300, 390),
            context="approvalCard overlay frame",
        )
        if not any(label.startswith("Deny") for label in button_labels):
            fail("missing required approval button label 'Deny'")
        if not any(label.startswith("Allow") for label in button_labels):
            fail("missing allow-style approval button label")

    elif scenario == "questionCard":
        if notch_status != "opened":
            fail(f"expected opened notch for questionCard, got {notch_status!r}")
        if not island_surface.startswith("sessionList:actionable("):
            fail(f"expected questionCard surface, got {island_surface!r}")
        require_overlay_frame_between(
            report,
            overlay_frame,
            notch_width=(660, 760),
            notch_height=(200, 340),
            context="questionCard overlay frame",
        )
        assert_contains_any(button_labels, ["10 秒", "鼠标离开收起", "都要"], "questionCard button labels")

    elif scenario == "completionCard":
        if notch_status != "opened":
            fail(f"expected opened notch for completionCard, got {notch_status!r}")
        if not island_surface.startswith("sessionList:actionable("):
            fail(f"expected completionCard surface, got {island_surface!r}")
        require_overlay_frame_between(
            report,
            overlay_frame,
            notch_width=(660, 760),
            notch_height=(240, 460),
            context="completionCard overlay frame",
        )
        if not ({"Done", "完成"} & text_values):
            fail("completionCard is missing completion text")

    elif scenario == "longCompletionCard":
        if notch_status != "opened":
            fail(f"expected opened notch for longCompletionCard, got {notch_status!r}")
        if not island_surface.startswith("sessionList:actionable("):
            fail(f"expected longCompletionCard to remain on completionCard surface, got {island_surface!r}")
        require_overlay_frame_between(
            report,
            overlay_frame,
            notch_width=(660, 760),
            notch_height=(240, 460),
            context="longCompletionCard overlay frame",
        )
        if not ({"Done", "完成"} & text_values):
            fail("longCompletionCard is missing completion text")
        assert_contains_any(text_values, ["README.md", "worktree"], "longCompletionCard text values")

    else:
        fail(f"unsupported scenario {scenario!r}")

    print(
        f"{scenario}: notch={notch_status}, surface={island_surface}, "
        f"frame={overlay_frame.get('width')}x{overlay_frame.get('height')}, "
        f"buttons={sorted(button_labels)}"
    )


if __name__ == "__main__":
    main()
