import { useEffect, useRef } from 'react';

export default function useInfiniteScroll(callback, enabled) {
  const sentinelRef = useRef(null);

  useEffect(() => {
    if (!enabled) return;
    const sentinel = sentinelRef.current;
    if (!sentinel) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          callback();
        }
      },
      { threshold: 0.1 }
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [callback, enabled]);

  return sentinelRef;
}
