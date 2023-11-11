import { faEnvelope } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

export default function Contact() {

  const email = "ivan@idimitrov.dev";
  const mailto = `mailto:${email}`

  return (
    <div className="w-full h-full p-2 grid place-content-center">
      <div className="flex flex-row gap-4">
        <a aria-label={mailto} href={mailto}><FontAwesomeIcon icon={faEnvelope} /></a>
      </div>
    </div>
  )
}
