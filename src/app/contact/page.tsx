import FolderSvg from "@/components/folder-svg";

const email = "ivan@idimitrov.dev";
const mailto = `mailto:${email}`;
const Contact = () => (
  <div className="w-full h-full p-12 grid grid-cols-12 gap-12">
    <div className="p-8 col-span-4">
      <p className="text-xl lg:text-2xl text-[#FB923C]">Available for projects</p>
    </div>
    <div className="relative col-span-8">
      <FolderSvg />
      <div className="relative grid w-max h-max grid-cols-2 grid-rows-2 gap-0">
        hehe
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
