import { useState, useRef } from 'react';
import styles from './MessageInput.module.css';

export default function MessageInput({ onSend, channel }) {
  const [value, setValue] = useState('');
  const textareaRef = useRef(null);

  const handleSubmit = () => {
    const trimmed = value.trim();
    if (!trimmed) return;
    onSend(trimmed);
    setValue('');
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const handleInput = (e) => {
    setValue(e.target.value);
    const el = e.target;
    el.style.height = 'auto';
    el.style.height = Math.min(el.scrollHeight, 120) + 'px';
  };

  return (
    <div className={styles.container}>
      <div className={styles.inputWrapper}>
        <textarea
          ref={textareaRef}
          className={styles.textarea}
          value={value}
          onChange={handleInput}
          onKeyDown={handleKeyDown}
          placeholder={`Message #${channel}`}
          rows={1}
        />
        <button
          className={styles.sendButton}
          onClick={handleSubmit}
          disabled={!value.trim()}
          aria-label="Send message"
        >
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
            <path d="M3 10l14-7-7 14v-7H3z" fill="currentColor" />
          </svg>
        </button>
      </div>
    </div>
  );
}
