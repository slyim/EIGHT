<template>
  <!-- Each slide names its part of the talk in frontmatter (`section:`); the cover and close have none. -->
  <footer v-if="$frontmatter?.section" class="deck-footer">
    <span>EIGHT · {{ $frontmatter.section }}</span>
    <span>{{ $page }} / {{ $nav.total }}</span>
  </footer>
</template>
