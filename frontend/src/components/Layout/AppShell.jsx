import { useState, useEffect, useCallback } from 'react';
import useChat from '../../hooks/useChat';
import useMediaQuery from '../../hooks/useMediaQuery';
import { getLastChannel } from '../../services/storage';
import { DEFAULT_CHANNELS } from '../../config/constants';
import Sidebar from './Sidebar';
import MembersPanel from './MembersPanel';
import BottomNav from './BottomNav';
import ChatArea from '../Chat/ChatArea';
import OfflineBanner from '../Shared/OfflineBanner';
import styles from './AppShell.module.css';

export default function AppShell() {
  const { activeChannel, setChannel, loadMessages } = useChat();
  const isMobile = useMediaQuery('(max-width: 639px)');
  const isTablet = useMediaQuery('(min-width: 640px) and (max-width: 1023px)');
  const [mobileTab, setMobileTab] = useState('chat');
  const [showMembers, setShowMembers] = useState(false);

  // Restore last channel on mount
  useEffect(() => {
    const saved = getLastChannel();
    if (saved) {
      setChannel(saved);
    } else {
      setChannel(DEFAULT_CHANNELS[0]);
    }
  }, [setChannel]);

  // Load messages when channel changes
  useEffect(() => {
    if (activeChannel) {
      loadMessages(activeChannel);
    }
  }, [activeChannel, loadMessages]);

  const handleSelectChannel = useCallback(
    (channel) => {
      setChannel(channel);
      if (isMobile) setMobileTab('chat');
    },
    [setChannel, isMobile]
  );

  if (isMobile) {
    return (
      <div className={styles.mobile}>
        <OfflineBanner />
        <div className={styles.mobileContent}>
          {mobileTab === 'channels' && (
            <Sidebar
              activeChannel={activeChannel}
              onSelectChannel={handleSelectChannel}
            />
          )}
          {mobileTab === 'chat' && <ChatArea />}
          {mobileTab === 'members' && (
            <MembersPanel channel={activeChannel} />
          )}
        </div>
        <BottomNav activeTab={mobileTab} onTabChange={setMobileTab} />
      </div>
    );
  }

  return (
    <div className={styles.desktop}>
      <OfflineBanner />
      <div className={styles.desktopContent}>
        <Sidebar
          activeChannel={activeChannel}
          onSelectChannel={handleSelectChannel}
        />
        <ChatArea />
        {!isTablet || showMembers ? (
          <MembersPanel channel={activeChannel} />
        ) : null}
        {isTablet && (
          <button
            className={styles.membersToggle}
            onClick={() => setShowMembers((v) => !v)}
            aria-label="Toggle members panel"
          >
            <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
              <path d="M12 4a4 4 0 110 8 4 4 0 010-8zM4 18c0-2.7 5.3-4 8-4s8 1.3 8 4v1H4v-1z" fill="currentColor" />
            </svg>
          </button>
        )}
      </div>
    </div>
  );
}
