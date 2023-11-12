"use client"
import { faCheck, faCopy } from "@fortawesome/free-solid-svg-icons"
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome"
import { useState } from "react"

type Props = {
  text: string
}

const CopyButton = ({ text }: Props) => {
  const [visible, setVisible] = useState("invisible")
  return (
    <button
      className="absolute top-5 right-5"
      onClick={() => {
        navigator.clipboard.writeText(text)
        setVisible("visible")
        setTimeout(() => setVisible("invisible"), 1000)
      }}
    >
      <span className={`${visible} absolute bottom-5 left-5`}><FontAwesomeIcon className="text-green-400" icon={faCheck} /></span>
      <FontAwesomeIcon className="" icon={faCopy} />
    </button>
  )
}

export default CopyButton;
