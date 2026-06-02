document.querySelectorAll("[data-video]").forEach((card) => {
    const src = card.dataset.video;
    const video = document.createElement("video");
    video.src = src;
    video.controls = true;
    video.autoplay = true;
    video.muted = true;
    video.playsInline = true;
    video.loop = true;
    video.preload = "metadata";

    video.addEventListener(
        "loadedmetadata",
        () => {
            const placeholder = card.querySelector(".video-placeholder");
            if (placeholder) {
                placeholder.replaceWith(video);
            }
        },
        { once: true }
    );
});

if (window.lucide) {
    window.lucide.createIcons();
}
