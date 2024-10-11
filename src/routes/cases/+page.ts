import { getCases } from "$lib/util/content"

export const load = async () => {
  return {
    cases: await getCases()
  }
}
