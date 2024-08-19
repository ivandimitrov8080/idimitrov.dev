const FolderSvg = () => (
  <svg
    className="absolute left-0 top-0 w-max"
    style={{ transform: "scaleX(-1)" }}
    width="592" height="447"
  >
    <path
      className="fill-none stroke-teal-50"
      d="
        M 25 0
        L 180 0
        C 180 0
          200 0
          230 30
        L 550 30
        S 580 30
          580 60
        L 580 400
        S 580 435
          550 435
        L 25 435
        S 0 435
          0 405
        L 0 25
        S 0 0
          30 0
        "
      style={{ strokeWidth: 3 }} />
  </svg>
)

export default FolderSvg;
