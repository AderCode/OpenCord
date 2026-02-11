import { useState } from 'react';
import { DEFAULT_CHANNELS } from '../../config/constants';
import ChannelItem from './ChannelItem';
import styles from './ChannelList.module.css';

export default function ChannelList({ activeChannel, onSelectChannel }) {
  const [customChannel, setCustomChannel] = useState('');
  const [channels, setChannels] = useState(DEFAULT_CHANNELS);

  const handleJoin = (e) => {
    e.preventDefault();
    const name = customChannel.trim().toLowerCase().replace(/[^a-z0-9-_]/g, '');
    if (name && !channels.includes(name)) {
      setChannels((prev) => [...prev, name]);
      onSelectChannel(name);
    } else if (name) {
      onSelectChannel(name);
    }
    setCustomChannel('');
  };

  return (
    <div className={styles.container}>
      <h3 className={styles.heading}>Channels</h3>
      <div className={styles.list}>
        {channels.map((ch) => (
          <ChannelItem
            key={ch}
            name={ch}
            isActive={ch === activeChannel}
            onClick={() => onSelectChannel(ch)}
          />
        ))}
      </div>
      <form className={styles.joinForm} onSubmit={handleJoin}>
        <input
          type="text"
          className={styles.input}
          placeholder="Join channel..."
          value={customChannel}
          onChange={(e) => setCustomChannel(e.target.value)}
          maxLength={32}
        />
      </form>
    </div>
  );
}
