"use client";

import { useEffect, useState } from "react";

type Props = {
  count: number;
};
const Stars = ({ count }: Props) => {
  const [width, setWidth] = useState(0);
  const [height, setHeight] = useState(0);

  useEffect(() => {
    setWidth(window.innerWidth);
    setHeight(window.innerHeight);
  }, []);

  const randomRgba = (alpha: number) => {
    return `rgba(${Math.random() * 255}, ${Math.random() * 255}, ${Math.random() * 255}, ${alpha})`
  }

  return (
    <div>
      {Array.from({ length: count }).map((_it, i) => {
        const radius = `${Math.random() * 7}px`
        return (
          <div
            key={i}
            style={{
              left: Math.random() * width,
              top: Math.random() * height,
              background: `radial-gradient(circle, ${randomRgba(1)} 0%, ${randomRgba(0)} 100%)`,
              width: radius,
              height: radius
            }}
            className="absolute z-10">
          </div>
        )
      })}
    </div>
  );
};

export default Stars;
