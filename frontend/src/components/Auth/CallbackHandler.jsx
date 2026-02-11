import { useEffect, useRef } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import useAuth from '../../hooks/useAuth';
import { exchangeCode } from '../../services/auth';
import LoadingSpinner from '../Shared/LoadingSpinner';

export default function CallbackHandler() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const { loginSuccess } = useAuth();
  const exchanged = useRef(false);

  useEffect(() => {
    const code = params.get('code');
    if (!code || exchanged.current) return;
    exchanged.current = true;

    exchangeCode(code)
      .then((tokens) => {
        loginSuccess(tokens);
        navigate('/', { replace: true });
      })
      .catch(() => {
        navigate('/login', { replace: true });
      });
  }, [params, loginSuccess, navigate]);

  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
      <LoadingSpinner />
    </div>
  );
}
