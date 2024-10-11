<script lang="ts">
  import CasesSvg from "$lib/components/cases-svg.svelte";
  import FolderSvg from "$lib/components/folder-svg.svelte";
  import GiteaSvg from "$lib/components/gitea-svg.svelte";
  import { faGithub, faLinkedin, faUpwork } from "@fortawesome/free-brands-svg-icons";
  import { FontAwesomeIcon } from "@fortawesome/svelte-fontawesome";
</script>

<div class="w-full h-full overflow-y-auto grid place-content-center">
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-7 lg:gap-0 w-full h-max p-7 lg:p-20">
    <div class="grid gap-6 pb-12">
      <div class="pt-0 lg:pt-12">
        <p class="text-xl lg:text-3xl text-[#FB923C]">Software Developer</p>
        <p class="text-4xl lg:text-8xl text-white capitalize">Full stack web development</p>
        <p
          class="text-4xl lg:text-8xl capitalize text-transparent font-bold bg-gradient-to-br from-transparent via-teal-400 to-yellow-400 bg-clip-text"
        >
          Refined
        </p>
      </div>
      <a aria-label="Cases" href="/" target="_blank" class="w-max">
        <CasesSvg />
      </a>
    </div>
    <div class="relative h-full grid place-content-center">
      <div class="absolute w-full h-full">
        <FolderSvg preserveAspectRatio={undefined} />
      </div>
      <div class="relative grid w-max h-max grid-cols-2 grid-rows-2 gap-0">
        <div class="absolute circle-gradient w-[1px] h-full left-1/2"></div>
        <div class="absolute circle-gradient w-full h-[1px] top-1/2"></div>
        <a
          class="p-5"
          aria-label="GitHub"
          href={"https://github.com/ivandimitrov8080"}
          target="_blank"
        >
          <FontAwesomeIcon icon={faGithub} />
        </a>
        <a
          class="p-5"
          aria-label="GitLab"
          href={"https://src.idimitrov.dev/ivandimitrov8080"}
          target="_blank"
        >
          <GiteaSvg />
        </a>
        <a
          class="p-5"
          aria-label="LinkedIn"
          href={"https://www.linkedin.com/in/devidimitrov"}
          target="_blank"
        >
          <FontAwesomeIcon icon={faLinkedin} />
        </a>
        <a
          class="p-5"
          aria-label="Upwork"
          href={"https://www.upwork.com/freelancers/idimitrov"}
          target="_blank"
        >
          <FontAwesomeIcon icon={faUpwork} />
        </a>
      </div>
    </div>

    <div class="flex flex-col lg:gap-12">
      <div class="w-full h-[1px] circle-gradient hidden lg:block"></div>
      <div class="flex flex-row gap-12">
        <div>
          <p class="text-3xl lg:text-6xl text-white capitalize">10+</p>
          <p class="text-md lg:text-xl text-white capitalize">Clients worldwide</p>
        </div>
        <div>
          <p class="text-3xl lg:text-6xl text-white capitalize">30+</p>
          <p class="text-md lg:text-xl text-white capitalize">Projects done</p>
        </div>
      </div>
    </div>
  </div>
</div>
