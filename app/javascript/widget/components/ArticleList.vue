<script>
import ArticleListItem from './ArticleListItem.vue';

export default {
  components: {
    ArticleListItem,
  },
  props: {
    articles: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {};
  },
  methods: {
    onClick(link) {
      this.$emit('click', link);
    },
  },
};
</script>

<template>
  <ul role="list" class="py-2">
    <ArticleListItem
      v-for="article in articles"
      :key="article.slug"
      :link="article.link"
      :title="article.title"
      @click="onClick"
    />
  </ul>
</template>
