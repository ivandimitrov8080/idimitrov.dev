import FolderSvg from "@/components/folder-svg";

const email = "ivan@idimitrov.dev";
const mailto = `mailto:${email}`;

const CheckSvg = () => (
  <svg width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M9.9502 11.7L8.5002 10.275C8.31686 10.0917 8.0877 10 7.8127 10C7.5377 10 7.3002 10.1 7.1002 10.3C6.91686 10.4833 6.8252 10.7167 6.8252 11C6.8252 11.2833 6.91686 11.5167 7.1002 11.7L9.2502 13.85C9.4502 14.05 9.68353 14.15 9.9502 14.15C10.2169 14.15 10.4502 14.05 10.6502 13.85L14.9002 9.6C15.1002 9.4 15.196 9.16666 15.1877 8.9C15.1794 8.63333 15.0835 8.4 14.9002 8.2C14.7002 8 14.4627 7.89583 14.1877 7.8875C13.9127 7.87916 13.6752 7.975 13.4752 8.175L9.9502 11.7ZM7.1502 20.75L5.7002 18.3L2.9502 17.7C2.7002 17.65 2.5002 17.5208 2.3502 17.3125C2.2002 17.1042 2.14186 16.875 2.1752 16.625L2.4502 13.8L0.575195 11.65C0.408529 11.4667 0.325195 11.25 0.325195 11C0.325195 10.75 0.408529 10.5333 0.575195 10.35L2.4502 8.2L2.1752 5.375C2.14186 5.125 2.2002 4.89583 2.3502 4.6875C2.5002 4.47916 2.7002 4.35 2.9502 4.3L5.7002 3.7L7.1502 1.25C7.28353 1.03333 7.46686 0.887497 7.7002 0.812497C7.93353 0.737497 8.16686 0.749997 8.4002 0.849997L11.0002 1.95L13.6002 0.849997C13.8335 0.749997 14.0669 0.737497 14.3002 0.812497C14.5335 0.887497 14.7169 1.03333 14.8502 1.25L16.3002 3.7L19.0502 4.3C19.3002 4.35 19.5002 4.47916 19.6502 4.6875C19.8002 4.89583 19.8585 5.125 19.8252 5.375L19.5502 8.2L21.4252 10.35C21.5919 10.5333 21.6752 10.75 21.6752 11C21.6752 11.25 21.5919 11.4667 21.4252 11.65L19.5502 13.8L19.8252 16.625C19.8585 16.875 19.8002 17.1042 19.6502 17.3125C19.5002 17.5208 19.3002 17.65 19.0502 17.7L16.3002 18.3L14.8502 20.75C14.7169 20.9667 14.5335 21.1125 14.3002 21.1875C14.0669 21.2625 13.8335 21.25 13.6002 21.15L11.0002 20.05L8.4002 21.15C8.16686 21.25 7.93353 21.2625 7.7002 21.1875C7.46686 21.1125 7.28353 20.9667 7.1502 20.75Z" fill="url(#paint0_linear_275_187)" />
    <defs>
      <linearGradient id="paint0_linear_275_187" x1="5.53038" y1="-4.2267" x2="25.9837" y2="17.1045" gradientUnits="userSpaceOnUse">
        <stop stop-color="#020617" />
        <stop offset="0.5" stop-color="#B91C1C" />
        <stop offset="1" stop-color="#FACC15" />
      </linearGradient>
    </defs>
  </svg>
)

const Contact = () => (
  <div className="w-full p-12 grid grid-cols-12 gap-12 basis-full">
    <div className="p-8 col-span-4 flex flex-col gap-4 h-min">
      <p className="text-xl lg:text-2xl text-[#FB923C]">Available for projects</p>
      <p className="text-4xl lg:text-6xl text-white capitalize">Get in touch</p>
      <p className="flex flex-row gap-2 text-xl lg:text-2xl text-white"><CheckSvg /> Schedule a consultation</p>
      <p className="flex flex-row gap-2 text-xl lg:text-2xl text-white"><CheckSvg /> Tell me about yourself and your project</p>
      <p className="flex flex-row gap-2 text-xl lg:text-2xl text-white"><CheckSvg /> Get advice for your needs</p>
    </div>
    <div className="col-span-8 h-full">
      <div className="relative">
        <FolderSvg />
      </div>
    </div>
  </div>
);

const test = () => {

  // <div className="flex flex-row gap-4">
  //   <a aria-label={mailto} href={mailto}>
  //     <FontAwesomeIcon className="w-14 h-14" icon={faEnvelope} />
  //   </a>
  //   <Link aria-label="GPG public key" href="/pgp.txt">
  //     <FontAwesomeIcon className="w-14 h-14" mask={faFile} icon={faLock} transform={"shrink-10 right-2 down-4"} />
  //   </Link>
  // </div>
}

export default Contact;
