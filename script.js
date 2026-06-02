const cards = document.querySelectorAll("[data-video]");

cards.forEach((card) => {
  const src = card.dataset.video;
  const video = document.createElement("video");
  video.controls = true;
  video.muted = true;
  video.playsInline = true;
  video.preload = "metadata";
  video.src = src;

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
