import { faEnvelope, faFile, faLock } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import Link from "next/link";

const email = "ivan@idimitrov.dev";
const mailto = `mailto:${email}`;
const Contact = () => (
  <div className="w-full h-full p-2 grid place-content-center">
    <div className="flex flex-row gap-4">
      <a aria-label={mailto} href={mailto}>
        <FontAwesomeIcon className="w-14 h-14" icon={faEnvelope} />
      </a>
      <Link aria-label="GPG public key" href="/pgp.txt">
        <FontAwesomeIcon className="w-14 h-14" mask={faFile} icon={faLock} transform={"shrink-10 right-2 down-4"} />
      </Link>
    </div>
  </div>
);

export default Contact;
