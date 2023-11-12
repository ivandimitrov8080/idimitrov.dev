import { faEnvelope } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const email = "ivan@idimitrov.dev";
const mailto = `mailto:${email}`
const Contact = () =>
  <div className="w-full h-full p-2 grid place-content-center">
    <div className="flex flex-row gap-4">
      <a aria-label={mailto} href={mailto}><FontAwesomeIcon className="svg-link" icon={faEnvelope} /></a>
    </div>
  </div>

export default Contact
