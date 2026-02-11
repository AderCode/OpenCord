import styles from './LoadingSpinner.module.css';

export default function LoadingSpinner({ size = 32 }) {
  return (
    <div
      className={styles.spinner}
      style={{ width: size, height: size }}
    />
  );
}
