const owner = "dot-RealityTest";
const repo = "apps";
const releasesUrl = `https://api.github.com/repos/${owner}/${repo}/releases/latest`;

const els = {
  tag: document.getElementById("release-tag"),
  status: document.getElementById("release-status"),
  asset: document.getElementById("release-asset"),
  date: document.getElementById("release-date"),
  note: document.getElementById("release-note"),
  primary: document.getElementById("download-link"),
  footer: document.getElementById("download-link-footer"),
};

function setDownloadLink(url, label) {
  els.primary.href = url;
  els.footer.href = url;
  if (label) {
    els.primary.textContent = label;
    els.footer.textContent = label;
  }
}

async function loadRelease() {
  try {
    const response = await fetch(releasesUrl, {
      headers: { Accept: "application/vnd.github+json" },
    });

    if (!response.ok) {
      throw new Error(`GitHub release lookup failed with ${response.status}`);
    }

    const release = await response.json();
    const dmgAsset = (release.assets || []).find((asset) =>
      asset.name.toLowerCase().endsWith(".dmg"),
    );

    const published = release.published_at
      ? new Date(release.published_at).toLocaleDateString("en-US", {
          year: "numeric",
          month: "short",
          day: "numeric",
        })
      : "Unknown";

    els.tag.textContent = release.tag_name || release.name || "Latest";
    els.status.textContent = release.prerelease ? "Pre-release" : "Stable";
    els.date.textContent = published;

    if (dmgAsset) {
      els.asset.textContent = `${dmgAsset.name} · ${Math.round(dmgAsset.size / 1024 / 1024)} MB`;
      setDownloadLink(
        dmgAsset.browser_download_url,
        `Download ${dmgAsset.name}`,
      );
      els.note.textContent = "Auto-linked to the latest DMG asset from GitHub Releases.";
    } else {
      els.asset.textContent = "No DMG asset found";
      setDownloadLink(release.html_url, "Open Latest Release");
      els.note.textContent =
        "The latest release did not expose a DMG asset, so the buttons fall back to the release page.";
    }
  } catch (error) {
    console.error(error);
    els.tag.textContent = "Unavailable";
    els.status.textContent = "GitHub API fallback";
    els.asset.textContent = "Use Releases page";
    els.date.textContent = "—";
    els.note.textContent =
      "GitHub metadata could not be loaded right now. Use the Releases page as a fallback.";
    setDownloadLink(`https://github.com/${owner}/${repo}/releases`, "View GitHub Releases");
  }
}

loadRelease();
