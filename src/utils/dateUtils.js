/**
 * Date and Time Utility for Parle DMS
 * Strictly enforces Indian Standard Time (IST, UTC+05:30) / Asia/Kolkata across all timestamps.
 */

export const IST_TIMEZONE = 'Asia/Kolkata';

/**
 * Format a date string or timestamp into IST
 * e.g., "22 Oct 2026, 09:30 PM IST"
 */
export function formatIST(dateInput, options = {}) {
  if (!dateInput) return '—';
  try {
    const date = new Date(dateInput);
    if (isNaN(date.getTime())) return String(dateInput);

    const defaultOptions = {
      timeZone: IST_TIMEZONE,
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: options.hideTime ? undefined : '2-digit',
      minute: options.hideTime ? undefined : '2-digit',
      hour12: true
    };

    const formatted = new Intl.DateTimeFormat('en-IN', { ...defaultOptions, ...options }).format(date);
    return options.hideTime ? formatted : `${formatted} IST`;
  } catch (e) {
    return String(dateInput);
  }
}

/**
 * Format date only in IST (e.g., "22 Oct 2026")
 */
export function formatISTDate(dateInput) {
  return formatIST(dateInput, { hideTime: true });
}

/**
 * Format time only in IST (e.g., "09:30:15 PM IST")
 */
export function formatISTTime(dateInput) {
  if (!dateInput) return '—';
  try {
    const date = new Date(dateInput);
    if (isNaN(date.getTime())) return String(dateInput);
    const formatted = new Intl.DateTimeFormat('en-IN', {
      timeZone: IST_TIMEZONE,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    }).format(date);
    return `${formatted} IST`;
  } catch (e) {
    return String(dateInput);
  }
}

/**
 * Get current timestamp formatted in IST
 */
export function getCurrentISTTimestamp() {
  return formatIST(new Date());
}
