"use client";

import { CSSProperties, useEffect, useState } from "react";

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

  const star = (key?: number) => {
    const radius = `${Math.random() * 7}px`
    let style: CSSProperties = {
      background: `radial-gradient(circle, ${randomRgba(0.6)} 0%, ${randomRgba(0)} 100%)`,
      width: radius,
      height: radius,
    };
    if (key) {
      style = {
        ...style,
        left: Math.random() * width,
        top: Math.random() * height
      }
    }
    return (
      <div
        key={key}
        style={style}
        className="absolute z-10">
      </div>
    )
  }

  const spinningStar = (key: number) => {
    const r = .1 + Math.random() * 1337
    const containerRadius = `${r}px`
    const duration = Math.floor(r) / 100;
    const x = Math.random() * width, y = Math.random() * height;
    const animation = Math.random() > .5 ? "spinner" : "spinner-reverse"
    return (
      <div
        key={key}
        style={{
          left: x,
          top: y,
          width: containerRadius,
          height: containerRadius,
          animation: `${animation} ${duration}s linear infinite`
        }}
        className="absolute z-10 max-w-full max-h-full">
        {star()}
      </div>
    )
  }

  return (
    <div className="absolute w-screen h-screen overflow-hidden">
      {Array.from({ length: count }).map((_it, i) => {
        return i % 4 === 0 ? spinningStar(i) : star(i)
      })}
    </div>
  );
};

export default Stars;
