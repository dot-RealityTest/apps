/**
 * DESIGN: Editorial Dark — Space Grotesk + Inter, deep charcoal bg,
 * electric green (#22c55e) for clean states, red-orange for dirty states.
 * Hacker video as full-bleed hero, asymmetric editorial layout.
 */

import { useEffect, useRef, useState } from "react";

const VIDEO_URL = "https://d2xsxph8kpxj0f.cloudfront.net/310519663256363840/2y8XLNBu2YAXAUHWvKqJb3/splash_hacker_final_656e107c.mp4";
const ICON_URL = "https://d2xsxph8kpxj0f.cloudfront.net/310519663256363840/2y8XLNBu2YAXAUHWvKqJb3/app-icon_367c4642.png";
const SPLASH_URL = "https://d2xsxph8kpxj0f.cloudfront.net/310519663256363840/2y8XLNBu2YAXAUHWvKqJb3/splash-reveal_7bc525ce.png";

// ─── Navbar ────────────────────────────────────────────────────────────────
function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <nav
      className="fixed top-0 left-0 right-0 z-50 transition-all duration-300"
      style={{
        background: scrolled ? "oklch(0.09 0.01 265 / 0.92)" : "transparent",
        backdropFilter: scrolled ? "blur(20px)" : "none",
        borderBottom: scrolled ? "1px solid oklch(1 0 0 / 0.06)" : "none",
      }}
    >
      <div className="container flex items-center justify-between py-4">
        <div className="flex items-center gap-3">
          <img src={ICON_URL} alt="ClipboardSanitizer icon" className="w-8 h-8 rounded-lg" />
          <span style={{ fontFamily: "'Space Grotesk', sans-serif", fontWeight: 700, fontSize: "1rem", color: "#fff" }}>
            ClipboardSanitizer
          </span>
        </div>
        <div className="hidden md:flex items-center gap-8">
          {["Features", "How It Works", "Download"].map((item) => (
            <a
              key={item}
              href={`#${item.toLowerCase().replace(/ /g, "-")}`}
              style={{
                fontFamily: "'Inter', sans-serif",
                fontSize: "0.875rem",
                color: "oklch(0.65 0.01 265)",
                textDecoration: "none",
                transition: "color 0.2s",
              }}
              onMouseEnter={(e) => (e.currentTarget.style.color = "#fff")}
              onMouseLeave={(e) => (e.currentTarget.style.color = "oklch(0.65 0.01 265)")}
            >
              {item}
            </a>
          ))}
        </div>
        <a href="#download" className="btn-primary" style={{ fontSize: "0.875rem", padding: "0.5rem 1.25rem" }}>
          Download Free
        </a>
      </div>
    </nav>
  );
}

// ─── Hero ───────────────────────────────────────────────────────────────────
function Hero() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [videoLoaded, setVideoLoaded] = useState(false);

  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.play().catch(() => {});
    }
  }, []);

  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden scanlines">
      {/* Video background */}
      <div className="absolute inset-0 z-0">
        <video
          ref={videoRef}
          src={VIDEO_URL}
          autoPlay
          loop
          muted
          playsInline
          onCanPlay={() => setVideoLoaded(true)}
          className="w-full h-full object-cover transition-opacity duration-1000"
          style={{ opacity: videoLoaded ? 1 : 0 }}
        />
        {/* Fallback poster */}
        {!videoLoaded && (
          <img src={SPLASH_URL} alt="ClipboardSanitizer" className="w-full h-full object-cover" />
        )}
        {/* Dark overlay for text readability */}
        <div
          className="absolute inset-0"
          style={{
            background: "linear-gradient(to bottom, oklch(0.09 0.01 265 / 0.55) 0%, oklch(0.09 0.01 265 / 0.3) 40%, oklch(0.09 0.01 265 / 0.75) 80%, oklch(0.09 0.01 265) 100%)",
          }}
        />
      </div>

      {/* Hero content */}
      <div className="container relative z-10 flex flex-col items-center text-center pt-24 pb-16">
        {/* Badge */}
        <div
          className="animate-fade-up inline-flex items-center gap-2 mb-8 px-4 py-2 rounded-full"
          style={{
            background: "oklch(0.72 0.19 145 / 0.12)",
            border: "1px solid oklch(0.72 0.19 145 / 0.3)",
          }}
        >
          <span style={{ width: 6, height: 6, borderRadius: "50%", background: "oklch(0.72 0.19 145)", display: "inline-block" }} className="animate-pulse" />
          <span className="mono" style={{ fontSize: "0.75rem", color: "oklch(0.72 0.19 145)", letterSpacing: "0.05em" }}>
            macOS Menu Bar App — Free
          </span>
        </div>

        {/* Headline */}
        <h1
          className="animate-fade-up-delay-1"
          style={{
            fontFamily: "'Space Grotesk', sans-serif",
            fontWeight: 700,
            fontSize: "clamp(2.5rem, 7vw, 5.5rem)",
            lineHeight: 1.05,
            letterSpacing: "-0.03em",
            color: "#fff",
            maxWidth: "900px",
            marginBottom: "1.5rem",
          }}
        >
          Copy messy.{" "}
          <span
            className="glitch-text"
            style={{
              background: "linear-gradient(135deg, oklch(0.72 0.19 145), oklch(0.85 0.15 145))",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text",
            }}
          >
            Paste perfect.
          </span>
        </h1>

        {/* Subheadline */}
        <p
          className="animate-fade-up-delay-2"
          style={{
            fontFamily: "'Inter', sans-serif",
            fontSize: "clamp(1rem, 2vw, 1.25rem)",
            color: "oklch(0.65 0.01 265)",
            maxWidth: "560px",
            lineHeight: 1.6,
            marginBottom: "2.5rem",
          }}
        >
          One shortcut strips rich formatting, kills tracking URLs, and normalizes whitespace — before you paste.
        </p>

        {/* CTA buttons */}
        <div className="animate-fade-up-delay-3 flex flex-col sm:flex-row items-center gap-4">
          <a href="#download" className="btn-primary animate-pulse-ring" style={{ fontSize: "1rem" }}>
            ↓ Download for macOS
          </a>
          <a href="#how-it-works" className="btn-ghost" style={{ fontSize: "1rem" }}>
            See how it works
          </a>
        </div>

        {/* Shortcut pill */}
        <div
          className="animate-fade-up-delay-4 mt-10 flex items-center gap-3"
          style={{ color: "oklch(0.45 0.01 265)", fontSize: "0.85rem", fontFamily: "'Inter', sans-serif" }}
        >
          <span>Trigger with</span>
          {["⌘", "⇧", "V"].map((key) => (
            <kbd
              key={key}
              style={{
                background: "oklch(0.18 0.01 265)",
                border: "1px solid oklch(1 0 0 / 0.12)",
                borderRadius: "0.35rem",
                padding: "0.2rem 0.55rem",
                fontFamily: "'JetBrains Mono', monospace",
                fontSize: "0.9rem",
                color: "#fff",
              }}
            >
              {key}
            </kbd>
          ))}
        </div>
      </div>

      {/* Scroll indicator */}
      <div
        className="absolute bottom-8 left-1/2 -translate-x-1/2 z-10 flex flex-col items-center gap-2"
        style={{ color: "oklch(0.35 0.01 265)", fontSize: "0.7rem", fontFamily: "'JetBrains Mono', monospace", letterSpacing: "0.1em" }}
      >
        <span>SCROLL</span>
        <div style={{ width: 1, height: 40, background: "linear-gradient(to bottom, oklch(0.35 0.01 265), transparent)" }} />
      </div>
    </section>
  );
}

// ─── Before / After Demo ────────────────────────────────────────────────────
function BeforeAfterDemo() {
  const BEFORE = `<b>Meeting Notes</b> — <span style="color:red">Q1 Review</span>
Action items:&nbsp;&nbsp;&nbsp;follow up with team
https://docs.google.com/doc?utm_source=email
  &fbclid=IwAR3xyzABC&ref=newsletter
• &nbsp;Deadline: <u>Friday</u>
• &nbsp;Owner: &lt;John&gt;`;

  const AFTER = `Meeting Notes — Q1 Review
Action items: follow up with team
https://docs.google.com/doc
• Deadline: Friday
• Owner: John`;

  return (
    <section id="features" className="py-24" style={{ background: "oklch(0.09 0.01 265)" }}>
      <div className="container">
        <div className="mb-16 max-w-2xl">
          <p className="mono mb-3" style={{ color: "oklch(0.72 0.19 145)", fontSize: "0.8rem", letterSpacing: "0.1em" }}>
            01 / WHAT IT DOES
          </p>
          <h2
            style={{
              fontFamily: "'Space Grotesk', sans-serif",
              fontWeight: 700,
              fontSize: "clamp(1.8rem, 4vw, 3rem)",
              letterSpacing: "-0.02em",
              color: "#fff",
              lineHeight: 1.1,
              marginBottom: "1rem",
            }}
          >
            Your clipboard,{" "}
            <span style={{ color: "oklch(0.72 0.19 145)" }}>stripped clean.</span>
          </h2>
          <p style={{ color: "oklch(0.55 0.01 265)", fontFamily: "'Inter', sans-serif", lineHeight: 1.7 }}>
            Press <code className="mono" style={{ color: "#fff", fontSize: "0.85em" }}>⌘⇧V</code> after copying anything. ClipboardSanitizer rewrites your clipboard in milliseconds — no UI, no friction.
          </p>
        </div>

        {/* Split demo */}
        <div className="grid md:grid-cols-2 gap-4">
          {/* Before */}
          <div
            style={{
              background: "oklch(0.07 0.01 265)",
              border: "1px solid oklch(0.65 0.22 25 / 0.25)",
              borderRadius: "1rem",
              overflow: "hidden",
            }}
          >
            <div
              className="flex items-center gap-2 px-5 py-3"
              style={{ borderBottom: "1px solid oklch(0.65 0.22 25 / 0.15)", background: "oklch(0.65 0.22 25 / 0.08)" }}
            >
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(0.65 0.22 25)" }} />
              <span className="mono" style={{ fontSize: "0.7rem", color: "oklch(0.65 0.22 25)", letterSpacing: "0.08em" }}>
                BEFORE — clipboard contents
              </span>
            </div>
            <pre
              className="code-block"
              style={{
                margin: 0,
                borderRadius: 0,
                border: "none",
                color: "oklch(0.65 0.22 25)",
                fontSize: "0.78rem",
                whiteSpace: "pre-wrap",
                wordBreak: "break-all",
              }}
            >
              {BEFORE}
            </pre>
          </div>

          {/* After */}
          <div
            style={{
              background: "oklch(0.07 0.01 265)",
              border: "1px solid oklch(0.72 0.19 145 / 0.25)",
              borderRadius: "1rem",
              overflow: "hidden",
            }}
          >
            <div
              className="flex items-center gap-2 px-5 py-3"
              style={{ borderBottom: "1px solid oklch(0.72 0.19 145 / 0.15)", background: "oklch(0.72 0.19 145 / 0.06)" }}
            >
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(0.72 0.19 145)" }} />
              <span className="mono" style={{ fontSize: "0.7rem", color: "oklch(0.72 0.19 145)", letterSpacing: "0.08em" }}>
                AFTER — ⌘⇧V applied
              </span>
            </div>
            <pre
              className="code-block"
              style={{
                margin: 0,
                borderRadius: 0,
                border: "none",
                color: "oklch(0.72 0.19 145)",
                fontSize: "0.78rem",
                whiteSpace: "pre-wrap",
              }}
            >
              {AFTER}
              <span className="cursor-blink" style={{ color: "oklch(0.72 0.19 145)" }}>█</span>
            </pre>
          </div>
        </div>
      </div>
    </section>
  );
}

// ─── Features Grid ──────────────────────────────────────────────────────────
const FEATURES = [
  {
    icon: "⌫",
    title: "Strip Rich Formatting",
    desc: "Removes bold, italic, colors, font sizes, and all HTML/RTF markup. What you paste is pure, clean plain text.",
    tag: "formatting",
  },
  {
    icon: "🔗",
    title: "Kill Tracking Parameters",
    desc: "Strips utm_source, fbclid, gclid, ref, and dozens of other tracking tokens from every URL you copy.",
    tag: "privacy",
  },
  {
    icon: "⎵",
    title: "Normalize Whitespace",
    desc: "Collapses multiple spaces, removes non-breaking spaces, and trims invisible characters that break layouts.",
    tag: "cleanup",
  },
  {
    icon: "⚡",
    title: "One Shortcut, Zero Friction",
    desc: "Lives in your menu bar. Press ⌘⇧V and it's done — no windows, no dialogs, no interruption to your flow.",
    tag: "speed",
  },
  {
    icon: "🔒",
    title: "100% Local & Private",
    desc: "No network requests. No cloud. Your clipboard never leaves your Mac. Open source and auditable.",
    tag: "privacy",
  },
  {
    icon: "🪶",
    title: "Featherweight",
    desc: "Uses negligible CPU and RAM. You'll forget it's running — until you need it.",
    tag: "performance",
  },
];

function FeaturesGrid() {
  return (
    <section style={{ background: "oklch(0.09 0.01 265)", paddingTop: "0", paddingBottom: "6rem" }}>
      <div className="container">
        <div className="section-divider mb-16" />
        <div className="mb-12">
          <p className="mono mb-3" style={{ color: "oklch(0.72 0.19 145)", fontSize: "0.8rem", letterSpacing: "0.1em" }}>
            02 / FEATURES
          </p>
          <h2
            style={{
              fontFamily: "'Space Grotesk', sans-serif",
              fontWeight: 700,
              fontSize: "clamp(1.8rem, 4vw, 3rem)",
              letterSpacing: "-0.02em",
              color: "#fff",
              lineHeight: 1.1,
            }}
          >
            Everything your clipboard<br />
            <span style={{ color: "oklch(0.55 0.01 265)" }}>should have been.</span>
          </h2>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {FEATURES.map((f) => (
            <div key={f.title} className="feature-card">
              <div
                className="mb-4 flex items-center justify-center"
                style={{
                  width: 44,
                  height: 44,
                  borderRadius: "0.75rem",
                  background: "oklch(0.72 0.19 145 / 0.1)",
                  fontSize: "1.3rem",
                }}
              >
                {f.icon}
              </div>
              <h3
                style={{
                  fontFamily: "'Space Grotesk', sans-serif",
                  fontWeight: 600,
                  fontSize: "1rem",
                  color: "#fff",
                  marginBottom: "0.5rem",
                  letterSpacing: "-0.01em",
                }}
              >
                {f.title}
              </h3>
              <p style={{ color: "oklch(0.55 0.01 265)", fontSize: "0.875rem", lineHeight: 1.65 }}>{f.desc}</p>
              <div
                className="mt-4 inline-block mono"
                style={{
                  fontSize: "0.65rem",
                  letterSpacing: "0.08em",
                  color: "oklch(0.72 0.19 145)",
                  background: "oklch(0.72 0.19 145 / 0.1)",
                  padding: "0.2rem 0.6rem",
                  borderRadius: "999px",
                  textTransform: "uppercase",
                }}
              >
                {f.tag}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── How It Works ───────────────────────────────────────────────────────────
const STEPS = [
  { num: "01", title: "Copy anything", desc: "Copy text from any app — a webpage, email, PDF, Slack message. Doesn't matter how messy." },
  { num: "02", title: "Press ⌘⇧V", desc: "Hit the global shortcut. ClipboardSanitizer intercepts your clipboard and rewrites it instantly." },
  { num: "03", title: "Paste clean text", desc: "Paste anywhere. No formatting noise, no trackers, no invisible junk. Just the content you wanted." },
];

function HowItWorks() {
  return (
    <section id="how-it-works" style={{ background: "oklch(0.07 0.01 265)", padding: "6rem 0" }}>
      <div className="container">
        <div className="mb-16">
          <p className="mono mb-3" style={{ color: "oklch(0.72 0.19 145)", fontSize: "0.8rem", letterSpacing: "0.1em" }}>
            03 / HOW IT WORKS
          </p>
          <h2
            style={{
              fontFamily: "'Space Grotesk', sans-serif",
              fontWeight: 700,
              fontSize: "clamp(1.8rem, 4vw, 3rem)",
              letterSpacing: "-0.02em",
              color: "#fff",
              lineHeight: 1.1,
            }}
          >
            Three steps.<br />
            <span style={{ color: "oklch(0.55 0.01 265)" }}>Zero workflow change.</span>
          </h2>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {STEPS.map((step, i) => (
            <div
              key={step.num}
              style={{
                position: "relative",
                padding: "2rem",
                borderRadius: "1rem",
                background: "oklch(0.09 0.01 265)",
                border: "1px solid oklch(1 0 0 / 0.06)",
              }}
            >
              {/* Connector line */}
              {i < STEPS.length - 1 && (
                <div
                  className="hidden md:block"
                  style={{
                    position: "absolute",
                    top: "2.5rem",
                    right: "-1.5rem",
                    width: "3rem",
                    height: 1,
                    background: "linear-gradient(to right, oklch(0.72 0.19 145 / 0.3), transparent)",
                    zIndex: 1,
                  }}
                />
              )}
              <div
                style={{
                  fontFamily: "'Space Grotesk', sans-serif",
                  fontWeight: 700,
                  fontSize: "3rem",
                  color: "oklch(0.72 0.19 145 / 0.15)",
                  lineHeight: 1,
                  marginBottom: "1rem",
                  letterSpacing: "-0.03em",
                }}
              >
                {step.num}
              </div>
              <h3
                style={{
                  fontFamily: "'Space Grotesk', sans-serif",
                  fontWeight: 600,
                  fontSize: "1.1rem",
                  color: "#fff",
                  marginBottom: "0.6rem",
                  letterSpacing: "-0.01em",
                }}
              >
                {step.title}
              </h3>
              <p style={{ color: "oklch(0.55 0.01 265)", fontSize: "0.875rem", lineHeight: 1.65 }}>{step.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── Social Proof / Quote ───────────────────────────────────────────────────
function SocialProof() {
  return (
    <section style={{ background: "oklch(0.09 0.01 265)", padding: "5rem 0" }}>
      <div className="container">
        <div className="section-divider mb-16" />
        <div className="grid md:grid-cols-3 gap-6">
          {[
            { quote: "I paste from Slack and email all day. This shortcut saves me from manually cleaning text every single time.", author: "Developer, remote team" },
            { quote: "The URL tracker removal alone is worth it. I share links constantly and never want to send tracking params to clients.", author: "Product Manager" },
            { quote: "Tiny app, massive quality-of-life improvement. It just runs quietly and does exactly what it promises.", author: "Designer & writer" },
          ].map((t) => (
            <div
              key={t.author}
              style={{
                background: "oklch(0.13 0.01 265)",
                border: "1px solid oklch(1 0 0 / 0.06)",
                borderRadius: "1rem",
                padding: "1.75rem",
              }}
            >
              <div style={{ color: "oklch(0.72 0.19 145)", fontSize: "1.5rem", marginBottom: "1rem", lineHeight: 1 }}>"</div>
              <p style={{ color: "oklch(0.75 0.01 265)", fontSize: "0.9rem", lineHeight: 1.7, marginBottom: "1.25rem" }}>{t.quote}</p>
              <p className="mono" style={{ color: "oklch(0.45 0.01 265)", fontSize: "0.72rem", letterSpacing: "0.05em" }}>
                — {t.author}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── Download CTA ───────────────────────────────────────────────────────────
function DownloadCTA() {
  return (
    <section
      id="download"
      style={{
        background: "oklch(0.07 0.01 265)",
        padding: "7rem 0",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Background glow */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          width: "600px",
          height: "300px",
          background: "radial-gradient(ellipse, oklch(0.72 0.19 145 / 0.07) 0%, transparent 70%)",
          pointerEvents: "none",
        }}
      />

      <div className="container relative z-10 flex flex-col items-center text-center">
        {/* App icon */}
        <img
          src={ICON_URL}
          alt="ClipboardSanitizer"
          className="animate-float mb-8"
          style={{ width: 96, height: 96, borderRadius: "22%", boxShadow: "0 0 40px oklch(0.72 0.19 145 / 0.2)" }}
        />

        <h2
          style={{
            fontFamily: "'Space Grotesk', sans-serif",
            fontWeight: 700,
            fontSize: "clamp(2rem, 5vw, 3.5rem)",
            letterSpacing: "-0.03em",
            color: "#fff",
            lineHeight: 1.05,
            marginBottom: "1rem",
          }}
        >
          Turn noisy copied text into<br />
          <span
            style={{
              background: "linear-gradient(135deg, oklch(0.72 0.19 145), oklch(0.85 0.15 145))",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text",
            }}
          >
            paste-ready content.
          </span>
        </h2>

        <p
          style={{
            color: "oklch(0.55 0.01 265)",
            fontFamily: "'Inter', sans-serif",
            fontSize: "1.05rem",
            maxWidth: "480px",
            lineHeight: 1.65,
            marginBottom: "2.5rem",
          }}
        >
          Free, open source, and runs entirely on your Mac. No subscriptions, no accounts, no nonsense.
        </p>

        <div className="flex flex-col sm:flex-row items-center gap-4">
          <a
            href="https://github.com/dot-RealityTest/clipboard-sanitizer-landing/releases/download/v1.0.0/ClipboardSanitizer.dmg"
            className="btn-primary animate-pulse-ring"
            style={{ fontSize: "1rem", display: "flex", alignItems: "center", gap: "0.5rem" }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z" />
            </svg>
            Download on GitHub
          </a>
          <a href="https://github.com/dot-RealityTest/clipboard-sanitizer-landing" className="btn-ghost" style={{ fontSize: "1rem" }}>
            View Source Code
          </a>
        </div>

        {/* Requirements note */}
        <p
          className="mono mt-8"
          style={{ color: "oklch(0.35 0.01 265)", fontSize: "0.72rem", letterSpacing: "0.05em" }}
        >
          Requires macOS 12+ · Apple Silicon &amp; Intel · Free &amp; Open Source
        </p>
      </div>
    </section>
  );
}

// ─── Footer ─────────────────────────────────────────────────────────────────
function Footer() {
  return (
    <footer style={{ background: "oklch(0.09 0.01 265)", borderTop: "1px solid oklch(1 0 0 / 0.06)", padding: "2.5rem 0" }}>
      <div className="container flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <img src={ICON_URL} alt="icon" style={{ width: 24, height: 24, borderRadius: "6px" }} />
          <span className="mono" style={{ fontSize: "0.75rem", color: "oklch(0.35 0.01 265)", letterSpacing: "0.05em" }}>
            ClipboardSanitizer
          </span>
        </div>
        <p className="mono" style={{ fontSize: "0.72rem", color: "oklch(0.3 0.01 265)", letterSpacing: "0.05em" }}>
          Free &amp; Open Source · No tracking · No accounts
        </p>
        <div className="flex items-center gap-4">
          <a
            href="https://www.akakika.com"
            className="mono"
            style={{ fontSize: "0.72rem", color: "oklch(0.45 0.01 265)", letterSpacing: "0.05em", textDecoration: "none" }}
            onMouseEnter={(e) => (e.currentTarget.style.color = "oklch(0.72 0.19 145)")}
            onMouseLeave={(e) => (e.currentTarget.style.color = "oklch(0.45 0.01 265)")}
          >
            Main Site →
          </a>
          <a
            href="/clipboardsanitizer/ClipboardSanitizer.dmg" download
            className="mono"
            style={{ fontSize: "0.72rem", color: "oklch(0.45 0.01 265)", letterSpacing: "0.05em", textDecoration: "none" }}
            onMouseEnter={(e) => (e.currentTarget.style.color = "oklch(0.72 0.19 145)")}
            onMouseLeave={(e) => (e.currentTarget.style.color = "oklch(0.45 0.01 265)")}
          >
            Download
          </a>
        </div>
      </div>
    </footer>
  );
}
export default Home;
