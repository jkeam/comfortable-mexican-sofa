(() => {
  const SLUGIFY_REPLACEMENTS = [
    [/[àáâã]/g, 'a'],
    [/ä/g, 'ae'],
    [/[èéëê]/g, 'e'],
    [/[ìíïî]/g, 'i'],
    [/[òóôõ]/g, 'o'],
    [/ö/g, 'oe'],
    [/[ùúû]/g, 'u'],
    [/ü/g, 'ue'],
    [/ñ/g, 'n'],
    [/ç/g, 'c'],
    [/ß/g, 'ss'],
    [/[·\/,:;_ ]/g, '-']
  ];

  const slugifyValue = (value) => {
    let slug = value.trim().toLowerCase();
    for (const [from, to] of SLUGIFY_REPLACEMENTS) {
      slug = slug.replace(from, to);
    }
    // Remove any other URL incompatible characters and replace multiple dashes with just a single one.
    return slug.replace(/[^a-z0-9-]/g, '').replace(/-+/g, '-');
  };

  window.CMS.slugify = () => {
    const input = document.querySelector('input[data-slugify=true]');
    const slugInputs = document.querySelectorAll('input[data-slug]');
    if (input === null || slugInputs === null) return;
    input.addEventListener('input', () => {
      slugInputs.forEach(function(slugInput) {
        slugInput.value = slugifyValue(input.value);
      });
    });
  };
})();
