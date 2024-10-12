<script lang="ts">
  import FolderSvg from "$lib/components/folder-svg.svelte";

  const checks = [
    "Schedule a consultation",
    "Tell me about yourself and your project",
    "Get advice for your needs"
  ];
</script>

<div
  class="w-full p-7 lg:p-12 grid lg:grid-cols-2 gap-12 basis-full overflow-y-auto overflow-x-hidden"
>
  <div class="lg:p-12 flex flex-col gap-12 justify-between">
    <div class="flex flex-col gap-4">
      <p class="text-xl lg:text-2xl text-[#FB923C]">Available for projects</p>
      <p class="text-4xl lg:text-6xl text-white capitalize">Get in touch</p>
      {#each checks as check}
        <p class="flex flex-row gap-2 text-lg lg:text-xl text-white">
          <svg
            class="w-8 h-8"
            width="22"
            height="22"
            viewBox="0 0 22 22"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M9.9502 11.7L8.5002 10.275C8.31686 10.0917 8.0877 10 7.8127 10C7.5377 10 7.3002 10.1 7.1002 10.3C6.91686 10.4833 6.8252 10.7167 6.8252 11C6.8252 11.2833 6.91686 11.5167 7.1002 11.7L9.2502 13.85C9.4502 14.05 9.68353 14.15 9.9502 14.15C10.2169 14.15 10.4502 14.05 10.6502 13.85L14.9002 9.6C15.1002 9.4 15.196 9.16666 15.1877 8.9C15.1794 8.63333 15.0835 8.4 14.9002 8.2C14.7002 8 14.4627 7.89583 14.1877 7.8875C13.9127 7.87916 13.6752 7.975 13.4752 8.175L9.9502 11.7ZM7.1502 20.75L5.7002 18.3L2.9502 17.7C2.7002 17.65 2.5002 17.5208 2.3502 17.3125C2.2002 17.1042 2.14186 16.875 2.1752 16.625L2.4502 13.8L0.575195 11.65C0.408529 11.4667 0.325195 11.25 0.325195 11C0.325195 10.75 0.408529 10.5333 0.575195 10.35L2.4502 8.2L2.1752 5.375C2.14186 5.125 2.2002 4.89583 2.3502 4.6875C2.5002 4.47916 2.7002 4.35 2.9502 4.3L5.7002 3.7L7.1502 1.25C7.28353 1.03333 7.46686 0.887497 7.7002 0.812497C7.93353 0.737497 8.16686 0.749997 8.4002 0.849997L11.0002 1.95L13.6002 0.849997C13.8335 0.749997 14.0669 0.737497 14.3002 0.812497C14.5335 0.887497 14.7169 1.03333 14.8502 1.25L16.3002 3.7L19.0502 4.3C19.3002 4.35 19.5002 4.47916 19.6502 4.6875C19.8002 4.89583 19.8585 5.125 19.8252 5.375L19.5502 8.2L21.4252 10.35C21.5919 10.5333 21.6752 10.75 21.6752 11C21.6752 11.25 21.5919 11.4667 21.4252 11.65L19.5502 13.8L19.8252 16.625C19.8585 16.875 19.8002 17.1042 19.6502 17.3125C19.5002 17.5208 19.3002 17.65 19.0502 17.7L16.3002 18.3L14.8502 20.75C14.7169 20.9667 14.5335 21.1125 14.3002 21.1875C14.0669 21.2625 13.8335 21.25 13.6002 21.15L11.0002 20.05L8.4002 21.15C8.16686 21.25 7.93353 21.2625 7.7002 21.1875C7.46686 21.1125 7.28353 20.9667 7.1502 20.75Z"
              fill="url(#paint0_linear_275_187)"
            />
            <defs>
              <linearGradient
                id="paint0_linear_275_187"
                x1="5.53038"
                y1="-4.2267"
                x2="25.9837"
                y2="17.1045"
                gradientUnits="userSpaceOnUse"
              >
                <stop stop-color="#020617" />
                <stop offset="0.5" stop-color="#B91C1C" />
                <stop offset="1" stop-color="#FACC15" />
              </linearGradient>
            </defs>
          </svg>
          {check}
        </p>
      {/each}
    </div>
    <div class="flex flex-col gap-4">
      <p class="text-lg lg:text-xl text-white">Encrypt your message using my public PGP key</p>
      <a
        target="_blank"
        class="w-max px-4 py-2 lg:px-10 rounded-full border-[1px] border-amber-50 z-50"
        aria-label="PGP key"
        href="/pgp"
      >
        <span class="flex flex-row gap-4 text-center w-max">
          <div>
            <svg
              class="w-full h-full"
              width="22"
              height="16"
              viewBox="0 0 22 16"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M10 7L3.3 2.8C3.01667 2.61667 2.72917 2.60833 2.4375 2.775C2.14583 2.94167 2 3.19167 2 3.525C2 3.675 2.03333 3.8125 2.1 3.9375C2.16667 4.0625 2.26667 4.16667 2.4 4.25L9.475 8.675C9.64167 8.775 9.81667 8.825 10 8.825C10.1833 8.825 10.3583 8.775 10.525 8.675L17.6 4.25C17.7333 4.16667 17.8333 4.0625 17.9 3.9375C17.9667 3.8125 18 3.675 18 3.525C18 3.19167 17.8542 2.94167 17.5625 2.775C17.2708 2.60833 16.9833 2.61667 16.7 2.8L10 7ZM17 16C16.7167 16 16.4792 15.9042 16.2875 15.7125C16.0958 15.5208 16 15.2833 16 15V12C16 11.7167 16.0958 11.4792 16.2875 11.2875C16.4792 11.0958 16.7167 11 17 11V10C17 9.45 17.1958 8.97917 17.5875 8.5875C17.9792 8.19583 18.45 8 19 8C19.55 8 20.0208 8.19583 20.4125 8.5875C20.8042 8.97917 21 9.45 21 10V11C21.2833 11 21.5208 11.0958 21.7125 11.2875C21.9042 11.4792 22 11.7167 22 12V15C22 15.2833 21.9042 15.5208 21.7125 15.7125C21.5208 15.9042 21.2833 16 21 16H17ZM18 11H20V10C20 9.71667 19.9042 9.47917 19.7125 9.2875C19.5208 9.09583 19.2833 9 19 9C18.7167 9 18.4792 9.09583 18.2875 9.2875C18.0958 9.47917 18 9.71667 18 10V11ZM2 16C1.45 16 0.979167 15.8042 0.5875 15.4125C0.195833 15.0208 0 14.55 0 14V2C0 1.45 0.195833 0.979167 0.5875 0.5875C0.979167 0.195833 1.45 0 2 0H18C18.55 0 19.0208 0.195833 19.4125 0.5875C19.8042 0.979167 20 1.45 20 2V5C20 5.28333 19.9042 5.52083 19.7125 5.7125C19.5208 5.90417 19.2833 6 19 6C17.6167 6 16.4375 6.4875 15.4625 7.4625C14.4875 8.4375 14 9.61667 14 11V15C14 15.2833 13.9042 15.5208 13.7125 15.7125C13.5208 15.9042 13.2833 16 13 16H2Z"
                fill="white"
              />
            </svg>
          </div>
          PGP key
        </span>
      </a>
    </div>
  </div>
  <div class="relative h-full">
    <div class="absolute w-full h-full z-10">
      <FolderSvg preserveAspectRatio="none" />
    </div>
    <form
      class="relative w-full h-full grid lg:grid-cols-2 place-content-center gap-8 z-40 p-12"
      action="/api/contact"
    >
      <div class="relative group border-b-[1px] border-neutral-500">
        <input
          aria-label="your name"
          name="name"
          required
          class="w-full h-10 px-4 text-sm peer bg-gray-100 outline-none bg-transparent"
        />
        <label
          for="name"
          class="pointer-events-none transform transition-all absolute top-0 left-0 h-full flex items-center pl-2 text-sm group-focus-within:text-xs peer-valid:text-xs group-focus-within:h-1/2 peer-valid:h-1/2 group-focus-within:-translate-y-full peer-valid:-translate-y-full group-focus-within:pl-0 peer-valid:pl-0"
        >
          Full name
        </label>
      </div>
      <div class="relative group border-b-[1px] border-neutral-500">
        <input
          aria-label="your email"
          type="email"
          name="email"
          required
          class="w-full h-10 px-4 text-sm peer bg-gray-100 outline-none bg-transparent"
        />
        <label
          for="email"
          class="pointer-events-none transform transition-all absolute top-0 left-0 h-full flex items-center pl-2 text-sm group-focus-within:text-xs peer-valid:text-xs group-focus-within:h-1/2 peer-valid:h-1/2 group-focus-within:-translate-y-full peer-valid:-translate-y-full group-focus-within:pl-0 peer-valid:pl-0"
        >
          Email
        </label>
      </div>
      <div class="lg:col-span-2 relative group border-b-[1px] border-neutral-500">
        <input
          aria-label="your message"
          name="message"
          required
          class="w-full h-10 px-4 text-sm peer bg-gray-100 outline-none bg-transparent"
        />
        <label
          for="message"
          class="pointer-events-none transform transition-all absolute top-0 left-0 h-full flex items-center pl-2 text-sm group-focus-within:text-xs peer-valid:text-xs group-focus-within:h-1/2 peer-valid:h-1/2 group-focus-within:-translate-y-full peer-valid:-translate-y-full group-focus-within:pl-0 peer-valid:pl-0"
        >
          Message
        </label>
      </div>
      <button
        class="lg:absolute lg:bottom-36 lg:right-12 w-max px-12 py-4 rounded-full z-50 gradient"
        aria-label="Send message"
        type="submit"
      >
        <span class="flex flex-row gap-4 text-center capitalize">Send message</span>
      </button>
    </form>
  </div>
</div>
