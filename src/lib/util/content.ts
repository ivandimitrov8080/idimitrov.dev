export const getCases = async () => {
  const allPostFiles = import.meta.glob("/src/routes/cases/*.svx");
  const iterablePostFiles = Object.entries(allPostFiles);

  const allPosts = await Promise.all(
    iterablePostFiles.map(async ([path, resolver]) => {
      const { metadata } = (await resolver()) as any;
      const postPath = path.slice(11, -4);

      return {
        meta: metadata,
        path: postPath
      };
    })
  );

  return allPosts.filter((p) => !p.meta.draft).sort((a, b) => Number(b.meta.z) - Number(a.meta.z));
};
