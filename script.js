document.querySelectorAll("[data-video]").forEach((card) => {
    const src = card.dataset.video;
    const placeholder = card.querySelector(".video-placeholder");
    const video = document.createElement("video");
    video.src = src;
    video.controls = true;
    video.autoplay = true;
    video.muted = true;
    video.playsInline = true;
    video.loop = true;
    video.preload = "metadata";
    video.style.display = "none";

    if (placeholder) {
        placeholder.replaceWith(video);
    } else {
        card.prepend(video);
    }

    const showVideo = () => {
        video.style.display = "block";
    };

    const showError = () => {
        video.remove();
        const error = document.createElement("div");
        error.className = "video-placeholder video-error";
        error.textContent = "Video unavailable in this browser. Re-encode to H.264 MP4 for web playback.";
        card.prepend(error);
    };

    video.addEventListener("loadedmetadata", showVideo, { once: true });
    video.addEventListener("error", showError, { once: true });
});

if (window.lucide) {
    window.lucide.createIcons();
}
