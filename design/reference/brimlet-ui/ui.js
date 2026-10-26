(() => {
'use strict';

const SYM = {
  'music.note': '<path d="M9 15.2V3.4l5.6 2.3"/><ellipse class="f" cx="6.9" cy="15.3" rx="2.5" ry="2.05"/>',
  'timer': '<circle cx="10" cy="11" r="6.4"/><path d="M8.1 2.75h3.8M10 11l2.7-2.7"/>',
  'calendar': '<rect x="3" y="4" width="14" height="13" rx="2.6"/><path d="M3 8.2h14M7 2.6v2.8M13 2.6v2.8"/>',
  'checklist': '<path d="m3 5.6 1.5 1.5L7 4.1M3 13.1l1.5 1.5 2.5-3M10.2 6h6.8M10.2 13.6h6.8"/>',
  'gearshape': '<circle cx="10" cy="10" r="2.5"/><path d="M8.6 2.75h2.8l.4 1.9 1.45.84 1.85-.6 1.4 2.42-1.45 1.3v1.68l1.45 1.3-1.4 2.42-1.85-.6-1.45.84-.4 1.9H8.6l-.4-1.9-1.45-.84-1.85.6-1.4-2.42 1.45-1.3V9.16l-1.45-1.3 1.4-2.42 1.85.6 1.45-.84.4-1.9Z"/>',
  'play.fill': '<path class="f" d="M6.4 4.2v11.6c0 .62.68.99 1.2.66l9.1-5.8a.78.78 0 0 0 0-1.32L7.6 3.54a.78.78 0 0 0-1.2.66Z"/>',
  'pause.fill': '<rect class="f" x="5.2" y="4" width="3.3" height="12" rx="1.1"/><rect class="f" x="11.5" y="4" width="3.3" height="12" rx="1.1"/>',
  'backward.fill': '<path class="f" d="M9.6 5.3v9.4c0 .52-.58.83-1.01.54L1.95 10.53a.64.64 0 0 1 0-1.06l6.64-4.71c.43-.29 1.01.02 1.01.54ZM18 5.3v9.4c0 .52-.58.83-1.01.54l-6.64-4.71a.64.64 0 0 1 0-1.06l6.64-4.71c.43-.29 1.01.02 1.01.54Z"/>',
  'forward.fill': '<path class="f" d="M10.4 5.3v9.4c0 .52.58.83 1.01.54l6.64-4.71a.64.64 0 0 0 0-1.06l-6.64-4.71c-.43-.29-1.01.02-1.01.54ZM2 5.3v9.4c0 .52.58.83 1.01.54l6.64-4.71a.64.64 0 0 0 0-1.06L3.01 4.76C2.58 4.47 2 4.78 2 5.3Z"/>',
  'quote.bubble': '<path d="M4.5 3.75h11c.97 0 1.75.78 1.75 1.75v7c0 .97-.78 1.75-1.75 1.75H9.2l-3.7 2.8v-2.8h-1c-.97 0-1.75-.78-1.75-1.75v-7c0-.97.78-1.75 1.75-1.75Z"/><path class="f" d="M7.1 7.1h2.1v2.1c0 1.05-.62 1.87-1.68 2.1l-.32-.62c.52-.2.85-.63.85-1.13h-.95Zm3.7 0h2.1v2.1c0 1.05-.62 1.87-1.68 2.1l-.32-.62c.52-.2.85-.63.85-1.13h-.95Z"/>',
  'arrow.up.right': '<path d="M6 14 14 6M7.6 6H14v6.4"/>',
  'arrow.clockwise': '<path d="M15.75 10a5.75 5.75 0 1 1-1.68-4.07"/><path d="M14.5 2.75v3.5H11"/>',
  'arrow.counterclockwise': '<path d="M4.25 10a5.75 5.75 0 1 0 1.68-4.07"/><path d="M5.5 2.75v3.5H9"/>',
  'plus': '<path d="M10 4.5v11M4.5 10h11"/>',
  'checkmark': '<path d="m4.5 10.4 3.6 3.6 7.4-8"/>',
  'checkmark.circle.fill': '<circle class="f" cx="10" cy="10" r="7.6"/><path class="cut" d="m6.8 10.2 2.2 2.2 4.3-4.6"/>',
  'checkmark.circle': '<circle cx="10" cy="10" r="7"/><path d="m6.8 10.2 2.2 2.2 4.3-4.6"/>',
  'circle': '<circle cx="10" cy="10" r="7"/>',
  'trash': '<path d="M4 5.5h12M8 5.5V4h4v1.5M5.5 5.5l.8 10.2c.06.73.66 1.3 1.4 1.3h4.6c.74 0 1.34-.57 1.4-1.3l.8-10.2M8.5 8.5v5.5M11.5 8.5v5.5"/>',
  'bell.fill': '<path class="f" d="M10 2.6c-2.85 0-4.9 2.15-4.9 4.95v3.15L3.65 13.3c-.3.5.07 1.1.64 1.1h11.42c.57 0 .94-.6.64-1.1L14.9 10.7V7.55c0-2.8-2.05-4.95-4.9-4.95Z"/><path class="f" d="M8 15.4h4a2 2 0 0 1-4 0Z"/>',
  'bell.badge': '<path d="M10 3.6c-2.65 0-4.65 2.05-4.65 4.7v2.55L4 13.2c-.25.45.07 1 .58 1h10.84c.51 0 .83-.55.58-1l-1.35-2.35V9.6"/><path d="M8.2 16.4a2 2 0 0 0 3.6 0"/><circle class="f" cx="14.6" cy="4.6" r="2.6"/>',
  'xmark': '<path d="m5.5 5.5 9 9M14.5 5.5l-9 9"/>',
  'bubbles': '<path class="f" d="M3.5 3.5h8A1.5 1.5 0 0 1 13 5v4.5a1.5 1.5 0 0 1-1.5 1.5H7l-2.75 2.2V11H3.5A1.5 1.5 0 0 1 2 9.5V5a1.5 1.5 0 0 1 1.5-1.5Z"/><path class="f" d="M14.5 7.5h2A1.5 1.5 0 0 1 18 9v4.5a1.5 1.5 0 0 1-1.5 1.5H16v2.2L13.25 15H9.5A1.5 1.5 0 0 1 8 13.5v-1h3.5a3 3 0 0 0 3-3Z"/>',
  'terminal.fill': '<rect class="f" x="2.5" y="3.5" width="15" height="13" rx="2.6"/><path class="cut" d="m6 8 2.5 2L6 12M10 12.4h4"/>',
  'lock': '<rect x="4.5" y="8.75" width="11" height="8.25" rx="2"/><path d="M7 8.75V6.5a3 3 0 0 1 6 0v2.25"/>',
  'lock.shield': '<path d="M10 2.6 4 4.85v4.35c0 3.7 2.5 6.6 6 8.2 3.5-1.6 6-4.5 6-8.2V4.85Z"/><rect class="f" x="7.4" y="9" width="5.2" height="4.1" rx=".8"/><path d="M8.45 9V7.95a1.55 1.55 0 0 1 3.1 0V9"/>',
  'exclamationmark.triangle.fill': '<path class="f" d="M8.48 3.1a1.75 1.75 0 0 1 3.04 0l6.3 11.03a1.75 1.75 0 0 1-1.52 2.62H3.7a1.75 1.75 0 0 1-1.52-2.62L8.48 3.1Z"/><path class="cut" d="M10 7.25v3.75"/><circle class="cut-f" cx="10" cy="13.6" r="1"/>',
  'calendar.badge.clock': '<path d="M17 9V6.6C17 5.16 15.84 4 14.4 4H5.6C4.16 4 3 5.16 3 6.6v7.8C3 15.84 4.16 17 5.6 17H9M3 8.2h14M7 2.6v2.8M13 2.6v2.8"/><circle cx="14.6" cy="14.6" r="3.4"/><path d="M14.6 12.9v1.8l1.15.8"/>',
  'calendar.badge.checkmark': '<path d="M17 9V6.6C17 5.16 15.84 4 14.4 4H5.6C4.16 4 3 5.16 3 6.6v7.8C3 15.84 4.16 17 5.6 17H9M3 8.2h14M7 2.6v2.8M13 2.6v2.8"/><circle cx="14.6" cy="14.6" r="3.4"/><path d="m13.1 14.7 1.05 1.05 1.95-2.15"/>',
  'quote.opening': '<path class="f" d="M3.6 9.6c0-3.1 1.65-5.15 4.45-5.95l.5 1.25C6.85 5.6 6.1 6.85 6 8.5h2.3v4.75H3.6Zm7.8 0c0-3.1 1.65-5.15 4.45-5.95l.5 1.25c-1.7.7-2.45 1.95-2.55 3.6h2.3v4.75h-4.7Z"/>',
  'square.stack.3d.up': '<path d="m10 3 7 3.5-7 3.5-7-3.5Z"/><path d="m3 10 7 3.5 7-3.5M3 13.5 10 17l7-3.5"/>',
  'line.3.horizontal': '<path d="M4 6h12M4 10h12M4 14h12"/>',
  'minus.circle': '<circle cx="10" cy="10" r="7"/><path d="M6.75 10h6.5"/>',
  'chevron.down': '<path d="m5 8 5 5 5-5"/>',
  'chevron.updown': '<path d="m6.8 7.6 3.2-3.2 3.2 3.2M6.8 12.4l3.2 3.2 3.2-3.2"/>',
  'headphones': '<path d="M3.6 13v-2.6a6.4 6.4 0 0 1 12.8 0V13"/><rect x="3" y="11.4" width="3.6" height="5.2" rx="1.2"/><rect x="13.4" y="11.4" width="3.6" height="5.2" rx="1.2"/>',
  'waveform': '<path d="M3 10h.5M6 7v6M9 3.8v12.4M12 6.4v7.2M15 8.4v3.2M17.5 10H17"/>',
  'house': '<path d="M3.5 9 10 3.5 16.5 9M5.5 7.5V16h9V7.5M8.5 16v-4h3v4"/>',
  'person': '<circle cx="10" cy="6.4" r="3"/><path d="M4 16.6c.6-3 3-4.6 6-4.6s5.4 1.6 6 4.6"/>',
  'briefcase': '<rect x="2.75" y="6" width="14.5" height="10" rx="2"/><path d="M7 6V4.5c0-.55.45-1 1-1h4c.55 0 1 .45 1 1V6M2.75 10.5h14.5"/>',
  'figure.walk': '<circle class="f" cx="11.2" cy="3.4" r="1.65"/><path d="M8.3 9.2 9.9 6.6l2.5.6 1.6 2.6M9.9 6.6l-1 5 2.7 2.4 1 3.4M8.9 11.6 7.1 14l-2.3 1.1M12.4 7.2 15 9"/>',
  'display': '<rect x="2.5" y="3.5" width="15" height="10" rx="1.6"/><path d="M7.5 17h5M10 13.5V17"/>',
  'arrow.down.circle': '<circle cx="10" cy="10" r="7"/><path d="M10 6.4v7.2M7 10.8l3 3 3-3"/>',
  'circle.hexagongrid': '<circle class="f" cx="10" cy="5.2" r="1.5"/><circle class="f" cx="5.8" cy="7.6" r="1.5"/><circle class="f" cx="14.2" cy="7.6" r="1.5"/><circle class="f" cx="10" cy="10" r="1.5"/><circle class="f" cx="5.8" cy="12.4" r="1.5"/><circle class="f" cx="14.2" cy="12.4" r="1.5"/><circle class="f" cx="10" cy="14.8" r="1.5"/>',
  'info.circle': '<circle cx="10" cy="10" r="7"/><path d="M10 9v4.6"/><circle class="f" cx="10" cy="6.5" r=".95"/>',
  'link': '<path d="M8.6 11.4a3 3 0 0 0 4.24 0l2.12-2.12a3 3 0 0 0-4.24-4.24l-.9.9"/><path d="M11.4 8.6a3 3 0 0 0-4.24 0L5.04 10.72a3 3 0 0 0 4.24 4.24l.9-.9"/>',
  'app.connected': '<rect x="3" y="3" width="14" height="14" rx="3.6"/><path d="m7 10.2 2.1 2.1L13.2 8"/>',
};
const sym = (name, cls = '') => `<svg class="sym ${cls}" viewBox="0 0 20 20" aria-hidden="true">${SYM[name] || ''}</svg>`;
const spin = () => '<svg class="spin" viewBox="0 0 16 16" aria-hidden="true"><path d="M8 1.6v2.6M8 11.8v2.6M1.6 8h2.6M11.8 8h2.6M3.5 3.5l1.8 1.8M10.7 10.7l1.8 1.8M3.5 12.5l1.8-1.8M10.7 5.3l1.8-1.8" opacity=".9"/></svg>';
const esc = (v) => String(v ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

const TR = {
  'Music': 'Müzik', 'Timer': 'Zamanlayıcı', 'Calendar': 'Takvim', 'Tasks': 'Yapılacaklar', 'Settings': 'Ayarlar',
  'Expand Brimlet': 'Brimlet’i genişlet', 'Collapse Brimlet': 'Brimlet’i küçült',
  'Open in Spotify': 'Spotify’da aç', 'Previous Track': 'Önceki parça', 'Next Track': 'Sonraki parça', 'Play': 'Oynat', 'Pause': 'Duraklat',
  'Show Lyrics': 'Sözleri göster', 'Hide Lyrics': 'Sözleri kapat', 'Lyrics': 'Sözler', 'Synced': 'Canlı', 'Plain': 'Düz metin',
  'Looking for lyrics…': 'Sözler aranıyor…', 'No lyrics found for this track.': 'Bu parça için söz bulunamadı.', 'Track position': 'Parça konumu',
  'A little room for your music.': 'Müziğine küçük bir alan.', 'What’s playing and its controls, right here.': 'Çalan parçan ve kontrollerin, tam burada.',
  'Connect to Spotify': 'Spotify’a bağlan', 'Play something, and it shows up here.': 'Bir parça aç, burada buluşalım.',
  'Brimlet is ready as soon as Spotify plays.': 'Spotify çalmaya başladığında Brimlet hazır.', 'Open Spotify': 'Spotify’ı aç',
  'Waiting for your next track.': 'Sıradaki parçanı bekliyor.', 'Start playing something in Spotify.': 'Spotify’da bir şeyler çalmaya başla.',
  'Brimlet needs your permission.': 'Spotify için izin gerekiyor.', 'Allow Spotify under Privacy & Security › Automation › Brimlet.': 'Gizlilik ve Güvenlik › Otomasyon › Brimlet altında Spotify’a izin ver.',
  'Open Privacy Settings': 'İzin ayarlarını aç', 'I’ve allowed it, try again': 'İzin verdim, yeniden dene', 'Let’s reconnect.': 'Bağlantıyı yenileyelim.',
  'Couldn’t read the track yet.': 'Parça bilgisi henüz alınamadı.', 'Try Again': 'Tekrar dene',
  '%d min': '%d dk', 'Start Timer': 'Zamanlayıcıyı başlat', 'Resume': 'Devam et', 'Start Again': 'Yeniden başlat', 'Reset Timer': 'Zamanlayıcıyı sıfırla',
  'Give yourself a little time.': 'Kendine biraz zaman ayır.', 'The clock is on your side.': 'Zaman senin için akıyor.', 'Paused. No rush.': 'Duraklatıldı. Acele yok.',
  'Time’s up.': 'Süre doldu.', 'Time’s up': 'Süre doldu', 'Take a breath. Start again when you’re ready.': 'Bir nefes al. Hazır olduğunda yeniden başla.', 'Your music keeps playing.': 'Müziğin çalmaya devam edebilir.',
  'Today': 'Bugün', 'Tomorrow': 'Yarın', '7 days': '7 gün', 'Refresh Calendar': 'Takvimi yenile', 'Open Calendar': 'Takvim’i aç', 'Join': 'Katıl', 'Show in Calendar': 'Etkinliği Takvim’de aç',
  'in %d min': '%d dk sonra', 'in %d h': '%d sa sonra', 'In progress': 'Devam ediyor', 'Ended': 'Sona erdi', 'All day': 'Tüm gün', 'Now': 'Şimdi', 'Day': 'Gün',
  'No events in this range': 'Bu aralıkta etkinlik yok', 'Choose which calendars to show in Settings.': 'Gösterilecek takvimleri Ayarlar’dan seçebilirsin.',
  'Your calendar, up top': 'Takvimin yukarıda', 'Allow calendar access to see your upcoming events.': 'Yaklaşan etkinliklerini görmek için takvim erişimini aç.',
  'Connect Calendar': 'Takvime bağlan', 'Couldn’t connect to Calendar. You can try again.': 'Takvime bağlanılamadı. Yeniden deneyebilirsin.',
  'Waiting for calendar access…': 'macOS takvim izni bekleniyor…', 'Calendar access is off': 'Takvim erişimi kapalı',
  'Turn on full access in System Settings › Privacy & Security › Calendars.': 'Sistem Ayarları › Gizlilik ve Güvenlik › Takvimler bölümünden tam erişimi aç.',
  'Calendar access is restricted on this Mac.': 'Bu Mac’te takvim erişimi sınırlandırılmış.', 'Open System Settings': 'Sistem Ayarları’nı aç',
  'The meeting link couldn’t be opened.': 'Toplantı bağlantısı açılamadı.', 'Join %@': '%@ toplantısına katıl',
  'All': 'Tümü', 'Home': 'Ev', 'Personal': 'Kişisel', 'Work': 'İş', 'New Task': 'Yeni görev', 'Completed': 'Tamamlananlar', 'Open Tasks': 'Aktif görevler', 'Undo': 'Geri al',
  'Nothing to do. Add a new task.': 'Liste boş. Yeni bir görev ekle.', 'Tasks completed in the last 30 days appear here.': 'Son 30 gündeki tamamlananlar burada görünür.', 'Delete': 'Sil',
  '“%@” completed': '“%@” tamamlandı', 'Complete Task': 'Görevi tamamla',
  'Sessions waiting for you': 'Cevap bekleyen oturumlar', 'Live · every 5 s': 'Canlı · 5 sn', '%@ · Waiting for your reply': '%@ · Yanıtını bekliyor',
  '%@ is waiting': '%@ yanıt bekliyor', '%@ · Open in cmux': '%@ · cmux’ta aç', 'Open this session in cmux': 'Bu oturumu cmux’ta aç',
  'No session is waiting for you.': 'Şu anda cevap bekleyen oturum yok.', '%d cmux sessions waiting for you': 'Cevap bekleyen %d cmux oturumu', '%d waiting': '%d bekliyor',
  'This space is yours': 'Alan sana ait', 'Start by turning on a module in Settings.': 'Ayarlar’dan bir modül ekleyerek başla.', 'Choose Modules': 'Modülleri aç',
  'Time to stretch': 'Esneme zamanı', 'You’ve been at your desk for an hour.': 'Bir saattir masa başındasın.', 'Click to dismiss': 'Kapatmak için tıkla',
  'One of your quotes': 'Sözlerinden biri', 'Add to Brimlet as Quote': 'Brimlet’e söz olarak ekle', 'Close': 'Kapat', 'Close Quote': 'Söz kartını kapat',
  '%d s · Waits while you hover': '%d sn · Üzerindeyken bekler', 'Open until you close it': 'Sen kapatana kadar açık', 'Person or author': 'Kişi / yazar', 'Book or source': 'Kitap veya kaynak',
  'Optional': 'İsteğe bağlı', 'Where it’s from is up to you.': 'Kaynak bilgisi isteğe bağlı.', 'Save': 'Kaydet',
  'What do you need to do?': 'Ne yapman gerekiyor?', 'Note (optional)': 'Not (isteğe bağlı)', 'Category': 'Kategori', 'Add a Date': 'Tarih ekle', 'Due': 'Bitiş tarihi',
  'Remind me at 9:00 that morning': 'Sabah 09.00’da hatırlat', 'macOS asks for permission the first time.': 'macOS ilk seferde izin ister.', 'Cancel': 'Vazgeç', 'Add': 'Ekle',
  'General': 'Genel', 'Modules': 'Modüller', 'Notifications': 'Bildirimler', 'Quotes': 'Özlü sözler',
  'Open at Login': 'Oturum açınca başlat', 'Starts Brimlet when you log in.': 'Oturum açtığında Brimlet’i başlatır.',
  'Open at Login couldn’t be changed. Move Brimlet to Applications and try again.': 'Otomatik başlatma değiştirilemedi. Brimlet’i Uygulamalar klasörüne taşıyıp tekrar dene.',
  'Allow Brimlet in System Settings › General › Login Items.': 'Sistem Ayarları › Genel › Giriş Öğeleri bölümünden Brimlet’e izin ver.',
  'On Screen': 'Ekranda', 'Display': 'Ekran', 'Automatic · Notched display first': 'Otomatik · Önce çentikli ekran', 'Chosen display isn’t connected': 'Seçilen ekran bağlı değil',
  'If the display goes away, Brimlet moves to another one. On displays without a notch it shows as a small capsule.': 'Ekran çıkarılırsa Brimlet açık olan başka bir ekrana geçer. Çentiksiz ekranlarda küçük bir kapsül olarak görünür.',
  'Expand on hover': 'Üzerine gelince genişlet', 'You can also click it open.': 'Kapalıyken tıklayarak da açabilirsin.', 'Hide in full screen': 'Tam ekranda gizle',
  'Leaves the space empty when an app fills the screen.': 'Ekranı kaplayan uygulamalarda alanı boş bırakır.',
  'Brimlet follows the Reduce Motion setting of macOS. Click its top bar to close it, or press Esc while it has keyboard focus.': 'Brimlet, macOS’in Hareketi Azalt ayarına uyar. Kapatmak için üst çubuğuna tıkla; panel klavye odağındayken Esc de kullanabilirsin.',
  'Show Brimlet': 'Brimlet’i göster', 'Updates': 'Güncellemeler', 'Check for updates automatically': 'Güncellemeleri otomatik denetle',
  'Once a day Brimlet asks GitHub for the latest version number.': 'Brimlet günde bir kez GitHub’dan en son sürüm numarasını sorar.',
  'Brimlet %@': 'Brimlet %@', 'Brimlet %@ is available': 'Brimlet %@ yayımlandı', 'Check Now': 'Şimdi denetle', 'Checking for updates…': 'Güncellemeler denetleniyor…',
  'This is the latest version.': 'Bu en son sürüm.', 'Not checked yet.': 'Henüz denetlenmedi.', 'Last checked: %@': 'Son denetim: %@', 'Couldn’t check for updates. %@': 'Güncellemeler denetlenemedi. %@',
  'GitHub is limiting requests. Try again later.': 'GitHub istekleri sınırlıyor. Daha sonra yeniden dene.', 'You have %@.': 'Kullandığın sürüm: %@.', 'Release Notes': 'Sürüm notları',
  'Download and Install': 'İndir ve kur', 'Downloading Brimlet %@': 'Brimlet %@ indiriliyor',
  'Drag Brimlet from the disk image to Applications and replace this version.': 'Brimlet’i disk görüntüsünden Uygulamalar klasörüne sürükleyip bu sürümün yerine koy.',
  'The download didn’t match its checksum and was deleted. The release page is open in your browser instead.': 'İndirilen dosya sağlama toplamıyla eşleşmedi ve silindi. Bunun yerine sürüm sayfası tarayıcında açıldı.',
  'This release has no checksum to verify the download, so its page is open in your browser instead.': 'Bu sürümde indirmeyi doğrulayacak bir sağlama toplamı yok; bu yüzden sayfası tarayıcında açıldı.',
  'Downloads the disk image and opens it, then Brimlet quits so you can drag the new version to Applications.': 'Disk görüntüsünü indirip açar; ardından Brimlet kapanır ve yeni sürümü Uygulamalar klasörüne sürükleyebilirsin.',
  'No account, no analytics.': 'Hesap yok, analitik yok.', 'Privacy': 'Gizlilik',
  'Brimlet asks for macOS Automation access only when you connect Spotify. It uses it to read the current track and control playback.': 'Brimlet, macOS Otomasyon iznini yalnızca Spotify’a bağlandığında ister. Bu izin parça bilgisini okumak ve oynatmayı kontrol etmek için kullanılır.',
  'Album art comes from Spotify’s servers and lyrics from LRCLIB. There is no account and no analytics, and nothing is sent to a server of ours.': 'Albüm kapakları Spotify’ın sunucularından, şarkı sözleri LRCLIB’den gelir. Hesap ve analitik yoktur; kendi sunucumuza hiçbir şey gönderilmez.',
  'Spotify · The track and playback controls': 'Spotify · Parça ve oynatma kontrolleri', 'A short break or some focus time': 'Kısa bir mola veya odaklanma zamanı',
  'Upcoming events and meeting links': 'Yaklaşan etkinlikler ve toplantı bağlantıları', 'Keep track of home, personal and work tasks': 'Ev, kişisel ve iş görevlerini takip et',
  'When several modules have something going on, the higher one wins. In the open panel, the tabs switch between them.': 'Birden fazla etkinlik varsa üstteki modül önceliklidir. Açık panelde sekmelerle istediğin modüle geçebilirsin.',
  'Move Up': 'Öne taşı', 'Move Down': 'Arkaya taşı', 'Drag to change the order': 'Sırayı değiştirmek için sürükle', 'Small View': 'Küçük görünüm',
  'Keep music in front': 'Müziği önde tut', 'The small view always shows the music module.': 'Küçük görünümde müzik modülünü sabitle.',
  'Show track changes': 'Parça değişimini göster', 'Briefly shows the new track.': 'Yeni parçayı kısa süreliğine gösterir.',
  'Play a sound when time’s up': 'Süre dolunca ses çal', 'A short sound when the timer ends.': 'Zamanlayıcı bittiğinde kısa bir ses duyulur.',
  'Connected to Spotify': 'Spotify bağlantısı', 'Not connected': 'Bağlı değil', 'Disconnect': 'Bağlantıyı kes', 'Turn on Music to connect Spotify.': 'Spotify’a bağlanmak için Müzik modülünü aç.',
  'Turning off the timer module resets a running timer.': 'Zamanlayıcı modülünü kapatmak çalışan süreyi sıfırlar.', 'The timer runs while Brimlet is open and ends when you quit it.': 'Zamanlayıcı uygulama açıkken çalışır; Brimlet’ten çıkıldığında sona erer.',
  'Event reminder': 'Etkinlik hatırlatması', 'Off': 'Kapalı', '5 minutes before': '5 dakika önce', '10 minutes before': '10 dakika önce',
  'Shows a short reminder while Brimlet is open and visible. Not for all-day events.': 'Brimlet açık ve görünürken kısa bir hatırlatma gösterir. Tüm gün etkinlikleri için gösterilmez.',
  'Calendars': 'Takvimler', 'All Calendars': 'Tüm takvimler', 'Your calendars appear here once Brimlet has access.': 'Takvim listesi erişim izni verildikten sonra burada görünür.',
  'No calendar is selected, so no events or reminders are shown.': 'Hiçbir takvim seçili değil. Etkinlikler ve hatırlatmalar gösterilmez.',
  'Turning on Calendar asks macOS for access. Events are only read; your calendar is never changed.': 'Takvim açıldığında macOS erişim izni ister. Etkinlikler yalnızca okunur; takviminde değişiklik yapılmaz.',
  'Calendar is off': 'Takvim kapalı', 'Turn On': 'Aç', 'Access': 'Erişim', 'Full access': 'Tam erişim', 'Not requested yet': 'Henüz istenmedi',
  'Notifications from other apps': 'Diğer uygulamaların bildirimleri', 'Apps you allow can show short notifications in Brimlet.': 'İzin verdiğin uygulamalar kısa bildirimlerini Brimlet’te gösterebilir.',
  'Allow an App…': 'Uygulamaya izin ver…', 'Remove': 'İzni kaldır', 'No apps allowed yet': 'Henüz izin verilen uygulama yok',
  'The app’s signature couldn’t be verified. Choose a signed app.': 'Uygulamanın imzası doğrulanamadı. İmzalanmış uygulama paketini seç.',
  'Notifications from other apps couldn’t be started. Try reopening Brimlet.': 'Yerel bildirim bağlantısı başlatılamadı. Brimlet’i yeniden açmayı dene.',
  'Show cmux sessions': 'cmux oturumlarını göster', 'Checks every 5 seconds for sessions waiting for your reply and opens them in cmux.': 'Cevap bekleyen canlı oturumları 5 saniyede bir yeniler; seçince cmux’ta açar.',
  'Show a quote now and then': 'Ara sıra bir söz göster', 'The card slides in from the right edge and leaves the modules alone.': 'Kart ekranın sağından açılır; modülleri bölmez.',
  'How often?': 'Ne sıklıkla?', 'Every 15 minutes': '15 dakikada bir', 'Every 30 minutes': '30 dakikada bir', 'Every hour': 'Saatte bir', 'Every 2 hours': '2 saatte bir',
  'Every 6 hours': '6 saatte bir', 'Every 12 hours': '12 saatte bir', 'Once a day': 'Günde bir', 'Every 2 days': '2 günde bir',
  'Stays on screen for': 'Ekranda kalma süresi', '10 seconds': '10 saniye', '15 seconds': '15 saniye', '30 seconds': '30 saniye', '1 minute': '1 dakika', '2 minutes': '2 dakika', 'Until I close it': 'Ben kapatana kadar',
  'The card stays while the pointer is on it. Close it any time with ×.': 'Kartın üzerindeyken kapanma süresi durur. İstediğin an × ile kapatabilirsin.',
  'Saved Quotes': 'Kayıtlı sözler', 'Show Now': 'Şimdi göster', 'Delete Quote': 'Sözü sil',
  'Select some text in a PDF or a web page, Control-click it and choose Services › Add to Brimlet as Quote.': 'PDF’te veya tarayıcıda bir metin seçip sağ tıkla; Servisler › Brimlet’e söz olarak ekle yoluyla buraya kaydedebilirsin.',
  'Your quotes are kept on this Mac. Quotes you haven’t seen yet come first.': 'Sözlerin bu Mac’te yerel olarak saklanır. Gösterim sırası, henüz gösterilmemiş sözlere öncelik verir.',
  'Update to %@…': '%@ sürümüne güncelle…', 'Open Brimlet': 'Brimlet’i aç', 'Show or Hide': 'Göster / Gizle', 'Settings…': 'Ayarlar…', 'Check for Updates…': 'Güncellemeleri denetle…', 'Quit Brimlet': 'Brimlet’ten çık',
  'Built-in Retina Display': 'Yerleşik Retina Ekran', 'Studio Display': 'Studio Display',
};
const t = (key, lang, ...args) => {
  let s = lang === 'tr' && TR[key] ? TR[key] : key;
  for (const a of args) s = s.replace(/%@|%d/, a);
  return s;
};

const DATA = {
  track: { title: 'Slow Tide', artist: 'Harbor Lights', duration: 316 },
  lyrics: ['Low light on the water', 'the harbor hums a slow refrain', 'we let the evening find us', 'and drift back home again', 'the gulls have gone to sleep now'],
  events: {
    today: [
      { id: 'e1', title: 'Weekly team sync', tr: 'Haftalık ekip buluşması', time: '14:28 – 14:58', cal: 'Work', calTr: 'İş', color: 'blue', st: ['in', 8], link: true },
      { id: 'e2', title: 'Design review', tr: 'Tasarım değerlendirmesi', time: '16:20 – 17:20', cal: 'Work', calTr: 'İş', color: 'blue', st: ['inh', 2], link: true },
      { id: 'e3', title: 'Pick up the bike from the repair shop', tr: 'Bisikleti tamirciden al', time: '18:00 – 18:30', cal: 'Home', calTr: 'Ev', color: 'green', st: ['inh', 4], link: false },
    ],
    tomorrow: [
      { id: 'e4', title: 'Dentist', tr: 'Diş hekimi', time: '09:30 – 10:15', cal: 'Personal', calTr: 'Kişisel', color: 'red', st: null, link: false },
      { id: 'e5', title: 'Quarterly planning with the product team', tr: 'Ürün ekibiyle üç aylık planlama toplantısı', time: '13:00 – 14:30', cal: 'Work', calTr: 'İş', color: 'blue', st: null, link: true },
    ],
  },
  tasks: [
    { id: 't1', t: 'Send the April invoice', tr: 'Nisan faturasını gönder', cat: 'work', due: 'Today', dueTr: 'Bugün', bell: true },
    { id: 't2', t: 'Pay the electricity bill', tr: 'Elektrik faturasını öde', cat: 'home', due: '28 Oct', dueTr: '28 Eki', bell: true },
    { id: 't3', t: 'Call the dentist', tr: 'Diş hekimini ara', cat: 'personal', note: 'Ask about Friday', noteTr: 'Cuma gününü sor' },
    { id: 't4', t: 'Book train tickets to Izmir', tr: 'İzmir tren biletlerini al', cat: 'personal' },
  ],
  done: [
    { id: 't5', t: 'Renew passport photos', tr: 'Pasaport fotoğraflarını yenile', cat: 'personal', done: true },
    { id: 't6', t: 'Water the balcony plants', tr: 'Balkon çiçeklerini sula', cat: 'home', done: true },
  ],
  sessions: [{ title: 'brimlet', agent: 'Claude Code' }, { title: 'findling', agent: 'Codex' }],
  quote: { text: 'I went to the woods because I wished to live deliberately, to front only the essential facts of life, and see if I could not learn what it had to teach, and not, when I came to die, discover that I had not lived.', author: 'Henry David Thoreau', source: 'Walden' },
  quotes: [
    { text: 'I went to the woods because I wished to live deliberately, to front only the essential facts of life, and see if I could not learn what it had to teach.', author: 'Henry David Thoreau', source: 'Walden' },
    { text: 'A sentence you want to remember.', tr: 'Hatırlamak istediğin bir cümle.', author: '', source: 'Notes', sourceTr: 'Notlar' },
  ],
  calendars: [
    { id: 'c1', title: 'Work', tr: 'İş', account: 'iCloud', color: 'blue' },
    { id: 'c2', title: 'Home', tr: 'Ev', account: 'iCloud', color: 'green' },
    { id: 'c3', title: 'Personal', tr: 'Kişisel', account: 'iCloud', color: 'red' },
    { id: 'c4', title: 'Team holidays', tr: 'Ekip tatilleri', account: 'Google · hamza@example.com', color: 'purple' },
    { id: 'c5', title: 'Birthdays', tr: 'Doğum günleri', account: 'Other', color: 'orange' },
  ],
};

const fmt = (sec) => { sec = Math.max(0, Math.round(sec)); return `${String(Math.floor(sec / 60)).padStart(2, '0')}:${String(sec % 60).padStart(2, '0')}`; };
const L = (o, lang, k) => {
  k = k || ('t' in o ? 't' : 'title' in o ? 'title' : 'text');
  const trk = k === 't' || k === 'title' || k === 'text' ? 'tr' : k + 'Tr';
  return (lang === 'tr' && o[trk]) || o[k];
};
const act = (s, a, extra = '') => s.interactive ? ` data-act="${a}"${extra}` : ' tabindex="-1"';

function geo(s) {
  const notch = s.notch !== false;
  const nw = s.notchWidth || 184;
  const head = notch ? Math.max(32, s.topInset || 38) : 36;
  const compact = notch ? nw + 108 : 218;
  const expanded = Math.min(Math.max(432, compact + 24), Math.max(280, (s.screenWidth || 1512) - 32));
  return { notch, nw, head, compact, expanded };
}
function islandSize(s) {
  const g = geo(s);
  if (s.mode === 'compact') return { w: g.compact, h: g.head, g };
  if (s.mode === 'peek') return { w: g.expanded, h: g.head + 66, g };
  const lyr = s.module === 'music' && s.music && s.music.lyrics && isPlaying(s.music);
  return { w: g.expanded, h: g.head + 236 + (lyr ? 164 : 0), g };
}
const isPlaying = (m) => m && (m.conn === 'playing' || m.conn === 'paused');
const art = (size, none) => `<span class="art${none ? ' is-none' : ''}" style="width:${size}px;height:${size}px;border-radius:${(size * 0.16).toFixed(1)}px" aria-hidden="true"></span>`;
const eq = (on, live) => `<span class="eq ${on ? 'is-on' : ''} ${live ? 'is-live' : 'is-idle'}" role="img" aria-label="${on ? 'Playing' : 'Paused'}"><i></i><i></i><i></i><i></i><i></i></span>`;

function headRight(s) {
  const expanded = s.mode === 'expanded';
  const live = (c) => expanded ? 'is-info' : c;
  const m = s.module;
  if (m === 'timer') {
    const tm = s.timer || {};
    if (tm.phase === 'running') return `<span class="isl-num ${live('is-live')}">${fmt(tm.remaining)}</span>`;
    if (tm.phase === 'paused') return `<span class="isl-num is-idle">${fmt(tm.remaining)}</span>`;
    if (tm.phase === 'finished') return sym('checkmark', 'isl-sym is-info');
    return sym('timer', 'isl-sym');
  }
  if (m === 'calendar') {
    const c = s.cal || {};
    const k = c.compact || 'in8';
    if (k === 'none') return `<span class="isl-num is-idle">–</span>`;
    if (k === 'now') return `<span class="isl-num ${live('is-live')}">${t('Now', s.lang)}</span>`;
    if (k === 'day') return `<span class="isl-num is-idle">${t('Day', s.lang)}</span>`;
    return `<span class="isl-num is-info">${t('%d min', s.lang, 8)}</span>`;
  }
  const mu = s.music || {};
  return eq(mu.conn === 'playing' && !s.reduceMotion, mu.conn === 'playing' && !expanded);
}
function headLeft(s) {
  const m = s.module;
  let inner;
  if ((m === 'music' || (s.mode === 'compact' && !m)) && isPlaying(s.music)) inner = art(22);
  else if (m) inner = sym({ music: 'music.note', timer: 'timer', calendar: 'calendar', todos: 'checklist' }[m], 'isl-sym');
  else inner = sym('circle.hexagongrid', 'isl-sym');
  const n = s.cmux && s.cmux.sessions ? s.cmux.sessions.length : 0;
  const badge = n ? `<span class="isl-badge" aria-label="${esc(t('%d cmux sessions waiting for you', s.lang, n))}">${n > 9 ? '9+' : n}</span>` : '';
  return inner + badge;
}

function tabs(s) {
  const mods = s.modules || ['music', 'timer', 'calendar', 'todos'];
  const icons = { music: 'music.note', timer: 'timer', calendar: 'calendar', todos: 'checklist' };
  const names = { music: 'Music', timer: 'Timer', calendar: 'Calendar', todos: 'Tasks' };
  const n = s.cmux && s.cmux.sessions ? s.cmux.sessions.length : 0;
  const chipW = n ? 62 + String(n).length * 7 + (s.lang === 'tr' ? 14 : 0) : 0;
  const titlesW = mods.reduce((sum, id) => sum + 39 + t(names[id], s.lang).length * 6.6, 0) + (mods.length - 1) * 4;
  const compactTitles = titlesW + 32 + (chipW ? chipW + 4 : 0) > (geo(s).expanded - 32);
  const items = mods.map((id) => {
    const sel = s.module === id && !(s.cmux && s.cmux.queue);
    const showTitle = !compactTitles || sel;
    const dot = id === 'timer' && s.timer && s.timer.phase === 'running' ? '<span class="dot" aria-hidden="true"></span>' : '';
    return `<button class="itab ${sel ? 'is-sel' : ''}" role="tab" aria-selected="${sel}" title="${esc(t(names[id], s.lang))}" aria-label="${esc(t(names[id], s.lang))}"${act(s, 'tab', ` data-v="${id}"`)}>${sym(icons[id])}${showTitle ? `<span>${t(names[id], s.lang)}</span>` : ''}${dot}</button>`;
  }).join('');
  const chip = n ? `<button class="ichip" title="${esc(t('Sessions waiting for you', s.lang))}"${act(s, 'cmuxq')}>${sym('bubbles')}${t('%d waiting', s.lang, n)}</button>` : '';
  return `<div class="itabs" role="tablist">${items}<span class="fill"></span>${chip}<button class="iicon" title="${esc(t('Settings', s.lang))}" aria-label="${esc(t('Settings', s.lang))}"${act(s, 'settings')}>${sym('gearshape')}</button></div>`;
}

function empty(s, symName, title, sub, primary, secondary) {
  const p = primary ? `<button class="ibtn ibtn-p"${act(s, primary[1])}>${esc(primary[0])}</button>` : '';
  const q = secondary ? `<button class="ibtn ibtn-t"${act(s, secondary[1])}>${esc(secondary[0])}</button>` : '';
  return `<div class="iempty">${symName === 'spin' ? spin() : sym(symName)}<p class="iempty-t">${esc(title)}</p>${sub ? `<p class="iempty-s">${esc(sub)}</p>` : ''}${p || q ? `<div class="acts">${p}${q}</div>` : ''}</div>`;
}

function music(s) {
  const m = s.music || {}; const lang = s.lang;
  if (!isPlaying(m)) {
    switch (m.conn) {
      case 'waiting': return empty(s, 'headphones', t('Play something, and it shows up here.', lang), t('Brimlet is ready as soon as Spotify plays.', lang), [t('Open Spotify', lang), 'noop']);
      case 'connected': return empty(s, 'waveform', t('Waiting for your next track.', lang), t('Start playing something in Spotify.', lang), [t('Open Spotify', lang), 'noop']);
      case 'denied': return empty(s, 'lock', t('Brimlet needs your permission.', lang), t('Allow Spotify under Privacy & Security › Automation › Brimlet.', lang), [t('Open Privacy Settings', lang), 'noop'], [t('I’ve allowed it, try again', lang), 'connect']);
      case 'failed': return empty(s, 'arrow.clockwise', t('Let’s reconnect.', lang), t('Couldn’t read the track yet.', lang), [t('Try Again', lang), 'connect']);
      default: return empty(s, 'music.note', t('A little room for your music.', lang), t('What’s playing and its controls, right here.', lang), [t('Connect to Spotify', lang), 'connect']);
    }
  }
  const tr = DATA.track; const el = m.elapsed ?? 92; const f = el / tr.duration;
  const playing = m.conn === 'playing';
  const dis = m.pending ? ' disabled' : '';
  let lyr = '';
  if (m.lyrics) {
    let body;
    if (m.lyrics === 'loading') body = `<div class="lyr-box" style="display:flex;align-items:center;gap:8px;color:var(--i-label-2);font:400 12px/16px var(--font-text)">${spin()}${t('Looking for lyrics…', lang)}</div>`;
    else if (m.lyrics === 'none') body = `<div class="lyr-box"><p class="i-s" style="font-size:12px;line-height:16px">${t('No lyrics found for this track.', lang)}</p></div>`;
    else {
      const a = m.lyrics === 'synced' ? (m.line ?? 1) : -1;
      const start = Math.max(0, Math.min(a - 1, DATA.lyrics.length - 4));
      body = `<div class="lyr-box">${DATA.lyrics.slice(start, start + 4).map((l, i) => `<span class="lyr-l ${i + start === a ? 'is-on' : ''}">${esc(l)}</span>`).join('')}</div>`;
    }
    const tag = m.lyrics === 'synced' ? `<span class="lyr-tag"><span class="dot"></span>${t('Synced', lang)}</span>` : (m.lyrics === 'plain' ? `<span class="lyr-tag">${t('Plain', lang)}</span>` : '');
    lyr = `<div class="lyr isurf" aria-label="${esc(t('Lyrics', lang))}"><div class="lyr-h"><span>${t('Lyrics', lang)}</span>${tag}</div>${body}</div>`;
  }
  return `<div class="mus">
    <div class="mus-top">${art(64)}<div style="flex:1 1 auto;min-width:0"><p class="mus-t i-trunc">${esc(tr.title)}</p><p class="mus-a i-trunc">${esc(tr.artist)}</p><p class="i-s i-s3" style="margin-top:3px">Spotify</p></div>
      <button class="iicon" title="${esc(t('Open in Spotify', lang))}" aria-label="${esc(t('Open in Spotify', lang))}"${act(s, 'noop')}>${sym('arrow.up.right')}</button></div>
    <div><div class="seek ${m.seekHover ? 'is-hover' : ''} ${m.pending ? 'is-off' : ''}" role="slider" aria-label="${esc(t('Track position', lang))}" aria-valuetext="${fmt(el)} / ${fmt(tr.duration)}" tabindex="${s.interactive ? 0 : -1}"${s.interactive ? ' data-act="seek"' : ''}><span class="tr"></span><span class="fl" style="width:${(f * 100).toFixed(2)}%"></span><span class="kn" style="left:${(f * 100).toFixed(2)}%"></span></div>
      <div class="times"><span>${fmt(el)}</span><span>−${fmt(tr.duration - el)}</span></div></div>
    <div class="trans">
      <button class="itrans" title="${esc(t('Previous Track', lang))}" aria-label="${esc(t('Previous Track', lang))}"${dis}${act(s, 'noop')}>${sym('backward.fill')}</button>
      <button class="iplay" title="${esc(t(playing ? 'Pause' : 'Play', lang))}" aria-label="${esc(t(playing ? 'Pause' : 'Play', lang))}"${dis}${act(s, 'playpause')}>${sym(playing ? 'pause.fill' : 'play.fill')}</button>
      <button class="itrans" title="${esc(t('Next Track', lang))}" aria-label="${esc(t('Next Track', lang))}"${dis}${act(s, 'noop')}>${sym('forward.fill')}</button>
      <button class="iicon ${m.lyrics ? 'is-on' : ''}" title="${esc(t(m.lyrics ? 'Hide Lyrics' : 'Show Lyrics', lang))}" aria-label="${esc(t(m.lyrics ? 'Hide Lyrics' : 'Show Lyrics', lang))}" aria-pressed="${!!m.lyrics}"${act(s, 'lyrics')}>${sym('quote.bubble')}</button>
    </div>${lyr}</div>`;
}

function timer(s) {
  const tm = s.timer || { phase: 'idle', sel: 25 }; const lang = s.lang;
  const total = (tm.total || tm.sel * 60 || 1500);
  const rem = tm.phase === 'idle' ? tm.sel * 60 : tm.remaining ?? total;
  const prog = tm.phase === 'idle' ? 0 : tm.phase === 'finished' ? 1 : Math.max(0, Math.min(1, rem / total));
  const C = 2 * Math.PI * 26;
  const off = tm.phase === 'finished' ? 0 : C * (1 - prog);
  const status = { idle: 'Give yourself a little time.', running: 'The clock is on your side.', paused: 'Paused. No rush.', finished: 'Time’s up.' }[tm.phase];
  const ring = `<div class="ring ${tm.phase === 'paused' ? 'is-paused' : ''} ${tm.phase === 'finished' ? 'is-done' : ''}" aria-hidden="true"><svg viewBox="0 0 56 56"><circle class="rt" cx="28" cy="28" r="26"/>${tm.phase === 'idle' ? '' : `<circle class="rp" cx="28" cy="28" r="26" stroke-dasharray="${C.toFixed(2)}" stroke-dashoffset="${off.toFixed(2)}"/>`}</svg><span class="rs">${sym(tm.phase === 'finished' ? 'checkmark' : 'timer')}</span></div>`;
  const reset = tm.phase !== 'idle' ? `<button class="iicon" title="${esc(t('Reset Timer', lang))}" aria-label="${esc(t('Reset Timer', lang))}"${act(s, 'treset')}>${sym('arrow.counterclockwise')}</button>` : '';
  let lower;
  if (tm.phase === 'idle') {
    lower = `<div class="iseg" role="radiogroup" aria-label="${esc(t('Timer', lang))}">${[5, 15, 25, 45].map((m) => `<button role="radio" aria-checked="${tm.sel === m}"${act(s, 'tsel', ` data-v="${m}"`)}>${t('%d min', lang, m)}</button>`).join('')}</div>
      <div class="tim-acts"><button class="ibtn ibtn-p"${act(s, 'tstart')}>${t('Start Timer', lang)}</button></div>`;
  } else if (tm.phase === 'finished') {
    lower = `<p class="tim-st">${t('Take a breath. Start again when you’re ready.', lang)}</p><div class="tim-acts"><button class="ibtn ibtn-p"${act(s, 'tstart')}>${t('Start Again', lang)}</button></div>`;
  } else {
    lower = `<p class="tim-st">${t('Your music keeps playing.', lang)}</p><div class="tim-acts">${tm.phase === 'running' ? `<button class="ibtn ibtn-s"${act(s, 'tpause')}>${t('Pause', lang)}</button>` : `<button class="ibtn ibtn-p"${act(s, 'tpause')}>${t('Resume', lang)}</button>`}</div>`;
  }
  return `<div style="display:grid;gap:14px;padding-top:2px"><div class="tim-top">${ring}<div style="flex:1 1 auto;min-width:0"><p class="tim-num" aria-live="off">${fmt(rem)}</p><p class="tim-st">${t(status, lang)}</p></div>${reset}</div>${lower}</div>`;
}

function evStatus(e, lang) {
  if (!e.st) return '';
  const [k, v] = e.st;
  if (k === 'now') return `<span class="i-live">${t('In progress', lang)}</span>`;
  if (k === 'ended') return `<span>${t('Ended', lang)}</span>`;
  if (k === 'allday') return `<span>${t('All day', lang)}</span>`;
  return `<span style="color:var(--i-label);font-weight:500">${k === 'in' ? t('in %d min', lang, v) : t('in %d h', lang, v)}</span>`;
}
function calendar(s) {
  const c = s.cal || { access: 'ready' }; const lang = s.lang;
  if (c.access === 'notRequested' || c.access === 'failed') return empty(s, 'calendar', t('Your calendar, up top', lang), t(c.access === 'failed' ? 'Couldn’t connect to Calendar. You can try again.' : 'Allow calendar access to see your upcoming events.', lang), [t('Connect Calendar', lang), 'calconnect']);
  if (c.access === 'requesting') return empty(s, 'spin', t('Waiting for calendar access…', lang), '');
  if (c.access === 'denied' || c.access === 'restricted') return empty(s, 'lock.shield', t('Calendar access is off', lang), t(c.access === 'restricted' ? 'Calendar access is restricted on this Mac.' : 'Turn on full access in System Settings › Privacy & Security › Calendars.', lang), c.access === 'restricted' ? null : [t('Open System Settings', lang), 'noop']);
  const range = c.range || 'today';
  const seg = `<div style="display:flex;align-items:center;gap:6px"><div class="iseg" role="radiogroup" aria-label="Agenda" style="flex:1 1 auto">${['today', 'tomorrow', 'week'].map((r) => `<button role="radio" aria-checked="${range === r}"${act(s, 'range', ` data-v="${r}"`)}>${t({ today: 'Today', tomorrow: 'Tomorrow', week: '7 days' }[r], lang)}</button>`).join('')}</div>
    <button class="iicon" title="${esc(t('Refresh Calendar', lang))}" aria-label="${esc(t('Refresh Calendar', lang))}"${act(s, 'noop')}>${sym('arrow.clockwise')}</button>
    <button class="iicon" title="${esc(t('Open Calendar', lang))}" aria-label="${esc(t('Open Calendar', lang))}"${act(s, 'noop')}>${sym('calendar')}</button></div>`;
  let list;
  const evs = c.empty ? [] : (c.events || (range === 'tomorrow' ? DATA.events.tomorrow : range === 'week' ? [...DATA.events.today, ...DATA.events.tomorrow] : DATA.events.today));
  if (c.loading) list = `<div class="iempty" style="height:132px">${spin()}</div>`;
  else if (!evs.length) list = `<div style="height:132px">${empty(s, 'calendar.badge.checkmark', t('No events in this range', lang), t('Choose which calendars to show in Settings.', lang))}</div>`;
  else {
    list = `<div style="height:${c.error ? 100 : 132}px;overflow:hidden;margin-top:8px">${evs.map((e, i) => {
      const soon = e.st && ((e.st[0] === 'in' && e.st[1] <= 10) || e.st[0] === 'now');
      const ended = e.st && e.st[0] === 'ended';
      const join = e.link && !ended ? `<button class="ibtn ${soon ? 'ibtn-p' : 'ibtn-s'}" aria-label="${esc(t('Join %@', lang, L(e, lang)))}"${act(s, 'noop')}>${t('Join', lang)}</button>` : '';
      const day = range === 'week' ? `<span>${i < 3 ? t('Today', lang) : t('Tomorrow', lang)}</span><span>·</span>` : '';
      const status = evStatus(e, lang);
      return `<div class="irow ${s.hoverRow === i ? 'is-hover' : ''}" style="${ended ? 'opacity:1' : ''}"><div style="flex:1 1 auto;min-width:0"><p class="i-t is-strong i-clamp2" style="${ended ? 'color:var(--i-label-3)' : ''}">${esc(L(e, lang))}</p>
        <p class="i-meta" style="margin-top:2px">${status}${status ? '<span>·</span>' : ''}${day}<span>${e.time}</span><span>·</span><span class="cdot" style="--c:var(--cal-${e.color})"></span><span class="grow">${esc(L(e, lang, 'cal'))}</span></p></div>
        ${join}<button class="iicon" title="${esc(t('Show in Calendar', lang))}" aria-label="${esc(t('Show in Calendar', lang))}"${act(s, 'noop')}>${sym('arrow.up.right')}</button></div>`;
    }).join('')}</div>`;
  }
  const err = c.error ? `<div class="inotice" style="margin-top:8px">${sym('exclamationmark.triangle.fill')}<span>${t('The meeting link couldn’t be opened.', lang)}</span></div>` : '';
  return seg + err + list;
}

function todos(s) {
  const d = s.todos || {}; const lang = s.lang;
  const cats = [[null, 'All'], ['home', 'Home'], ['personal', 'Personal'], ['work', 'Work']];
  const head = `<div style="display:flex;align-items:center;gap:6px"><div class="iseg" role="radiogroup" aria-label="${esc(t('Category', lang))}" style="flex:1 1 auto">${cats.map(([v, n]) => `<button role="radio" aria-checked="${(d.filter || null) === v}"${act(s, 'filter', ` data-v="${v || ''}"`)}>${t(n, lang)}</button>`).join('')}</div>
    <button class="iicon ${d.showCompleted ? 'is-on' : ''}" title="${esc(t(d.showCompleted ? 'Open Tasks' : 'Completed', lang))}" aria-label="${esc(t('Completed', lang))}" aria-pressed="${!!d.showCompleted}"${act(s, 'showdone')}>${sym('checkmark.circle')}</button>
    <button class="iicon is-accent" title="${esc(t('New Task', lang))}" aria-label="${esc(t('New Task', lang))}"${d.showCompleted ? ' disabled' : ''}${act(s, 'newtask')}>${sym('plus')}</button></div>`;
  const src = d.showCompleted ? (d.done || DATA.done) : (d.items || DATA.tasks);
  const items = src.filter((i) => !d.filter || i.cat === d.filter);
  let list;
  if (!items.length) list = `<p class="i-s" style="padding:14px 2px;font-size:12px;line-height:16px">${t(d.showCompleted ? 'Tasks completed in the last 30 days appear here.' : 'Nothing to do. Add a new task.', lang)}</p>`;
  else list = items.map((i) => {
    const meta = [`<span>${t({ home: 'Home', personal: 'Personal', work: 'Work' }[i.cat], lang)}</span>`];
    if (i.due) meta.push('<span>·</span>', `<span>${esc(L(i, lang, 'due'))}</span>`);
    if (i.bell) meta.push(sym('bell.fill'));
    if (i.note) meta.push('<span>·</span>', `<span class="grow">${esc(L(i, lang, 'note'))}</span>`);
    const done = !!i.done;
    return `<div class="irow" style="min-height:40px;padding:6px 8px">
      <button class="iicon" style="width:24px;height:24px;${done ? 'color:var(--i-accent)' : ''}" title="${esc(t('Complete Task', lang))}" aria-label="${esc(t('Complete Task', lang))}"${done ? ' disabled' : ''}${act(s, 'complete', ` data-v="${i.id}"`)}>${sym(done ? 'checkmark.circle.fill' : 'circle')}</button>
      <div style="flex:1 1 auto;min-width:0"><p class="i-t i-trunc" style="${done ? 'text-decoration:line-through;color:var(--i-label-3)' : ''}">${esc(L(i, lang))}</p><p class="i-meta">${meta.join('')}</p></div>
      ${done ? `<button class="iicon" title="${esc(t('Delete', lang))}" aria-label="${esc(t('Delete', lang))}"${act(s, 'remove', ` data-v="${i.id}"`)}>${sym('trash')}</button>` : ''}</div>`;
  }).join('');
  const undo = d.undo ? `<div class="irow" style="position:absolute;left:20px;right:20px;bottom:10px;background:var(--i-raised);box-shadow:0 8px 20px -6px rgba(0,0,0,.6)" role="status"><span class="i-t i-trunc" style="flex:1 1 auto">${esc(t('“%@” completed', lang, d.undo))}</span><button class="ibtn ibtn-tl"${act(s, 'undo')}>${t('Undo', lang)}</button></div>` : '';
  return `${head}<div style="height:144px;overflow:hidden;margin-top:8px">${list}</div>${undo}`;
}

function cmuxQueue(s) {
  const lang = s.lang; const ss = (s.cmux && s.cmux.sessions) || [];
  const head = `<div style="display:flex;align-items:baseline;justify-content:space-between;margin-bottom:8px"><p class="i-t is-strong">${t('Sessions waiting for you', lang)}</p><p class="i-s i-s3">${t('Live · every 5 s', lang)}</p></div>`;
  if (!ss.length) return head + `<p class="i-s" style="padding-top:20px;font-size:12px">${t('No session is waiting for you.', lang)}</p>`;
  return head + ss.map((x) => `<button class="irow" style="width:100%;border:0;color:inherit;text-align:left" title="${esc(t('Open this session in cmux', lang))}"${act(s, 'noop')}><span class="sw-ico" style="color:var(--i-label-2)">${sym('terminal.fill')}</span><span style="flex:1 1 auto;min-width:0"><span class="i-t i-trunc">${esc(x.title)}</span><span class="i-s i-trunc">${esc(t('%@ · Waiting for your reply', lang, x.agent))}</span></span>${sym('arrow.up.right', 'isl-sym')}</button>`).join('');
}

function peek(s) {
  const p = s.peek || { kind: 'music' }; const lang = s.lang;
  if (p.kind === 'external') {
    const n = p.n || { title: t('Time to stretch', lang), body: t('You’ve been at your desk for an hour.', lang), symbol: 'figure.walk' };
    return `<div class="pk" role="status" title="${esc(t('Click to dismiss', lang))}"${s.interactive ? ' data-act="dismiss"' : ''}><span class="pk-tile">${sym(n.symbol)}</span><div style="flex:1 1 auto;min-width:0"><p class="pk-t i-trunc">${esc(n.title)}</p><p class="pk-s i-clamp2">${esc(n.body)}</p></div></div>`;
  }
  if (p.kind === 'cmux') {
    const ss = (s.cmux && s.cmux.sessions) || DATA.sessions; const x = ss[0];
    return `<div class="pk"><button class="pk-open ${p.hover ? 'is-hover' : ''}" title="${esc(t('Open this session in cmux', lang))}"${act(s, 'noop')}><span class="pk-tile is-accent">${sym('bubbles')}</span><span style="flex:1 1 auto;min-width:0"><span class="pk-t i-trunc" style="display:block">${esc(t('%@ is waiting', lang, x.title))}</span><span class="pk-s i-trunc" style="display:block">${esc(t('%@ · Open in cmux', lang, x.agent))}</span></span>${ss.length > 1 ? `<span class="ichip">+${ss.length - 1}</span>` : ''}${sym('arrow.up.right', 'isl-sym')}</button></div>`;
  }
  if (p.kind === 'calendar') {
    const e = DATA.events.today[0];
    return `<div class="pk"><button class="pk-open ${p.hover ? 'is-hover' : ''}" title="${esc(t('Expand Brimlet', lang))}"${act(s, 'expand')}><span class="pk-tile">${sym('calendar.badge.clock')}</span><span style="flex:1 1 auto;min-width:0"><span class="pk-t i-trunc" style="display:block">${esc(L(e, lang))}</span><span class="i-meta" style="font-size:12px;line-height:16px"><span style="color:var(--i-label);font-weight:500">${t('in %d min', lang, 5)}</span><span>·</span><span class="cdot" style="--c:var(--cal-blue)"></span><span>${esc(L(e, lang, 'cal'))}</span></span></span></button><div class="pk-ctl"><button class="ibtn ibtn-p" aria-label="${esc(t('Join %@', lang, L(e, lang)))}"${act(s, 'noop')}>${t('Join', lang)}</button></div></div>`;
  }
  if (p.kind === 'timer') {
    return `<div class="pk"><button class="pk-open ${p.hover ? 'is-hover' : ''}" title="${esc(t('Expand Brimlet', lang))}"${act(s, 'expand')}><span class="pk-tile is-accent">${sym('checkmark')}</span><span style="flex:1 1 auto;min-width:0"><span class="pk-t" style="display:block">${t('Time’s up', lang)}</span><span class="pk-s" style="display:block">${t('Timer', lang)}</span></span></button></div>`;
  }
  const m = s.music || { conn: 'playing' }; const playing = m.conn === 'playing'; const dis = m.pending ? ' disabled' : '';
  return `<div class="pk"><button class="pk-open ${p.hover ? 'is-hover' : ''}" title="${esc(t('Expand Brimlet', lang))}"${act(s, 'expand')}>${art(40)}<span style="flex:1 1 auto;min-width:0"><span class="pk-t i-trunc" style="display:block">${esc(DATA.track.title)}</span><span class="pk-s i-trunc" style="display:block">${esc(DATA.track.artist)}</span></span></button>
    <div class="pk-ctl" style="${m.pending ? 'opacity:.45' : ''}"><button class="itrans is-small" title="${esc(t('Previous Track', lang))}" aria-label="${esc(t('Previous Track', lang))}"${dis}${act(s, 'noop')}>${sym('backward.fill')}</button><button class="iplay is-small" title="${esc(t(playing ? 'Pause' : 'Play', lang))}" aria-label="${esc(t(playing ? 'Pause' : 'Play', lang))}"${dis}${act(s, 'playpause')}>${sym(playing ? 'pause.fill' : 'play.fill')}</button><button class="itrans is-small" title="${esc(t('Next Track', lang))}" aria-label="${esc(t('Next Track', lang))}"${dis}${act(s, 'noop')}>${sym('forward.fill')}</button><button class="iicon" title="${esc(t('Show Lyrics', lang))}" aria-label="${esc(t('Show Lyrics', lang))}"${act(s, 'peeklyrics')}>${sym('quote.bubble')}</button></div></div>`;
}

function island(s) {
  const { w, h, g } = islandSize(s);
  const cls = ['isl', g.notch ? '' : 'is-capsule', s.mode === 'compact' ? 'is-compact' : '', s.noAnim ? 'no-anim' : ''].join(' ');
  const label = s.mode === 'expanded' ? t('Collapse Brimlet', s.lang) : t('Expand Brimlet', s.lang);
  const head = `<div class="isl-head" style="height:${g.head}px"><button class="isl-head-btn" aria-label="${esc(label)}" title="${esc(label)}"${act(s, 'head')}></button><span class="isl-slot">${headLeft(s)}</span><span class="isl-spacer"></span>${g.notch ? `<span class="isl-cam" style="width:${g.nw}px" aria-hidden="true"></span><span class="isl-spacer"></span>` : ''}<span class="isl-slot">${headRight(s)}</span></div>`;
  let body = '';
  if (s.mode === 'peek') body = peek(s);
  if (s.mode === 'expanded') {
    let content;
    if (s.cmux && s.cmux.queue) content = cmuxQueue(s);
    else if (!s.module) content = empty(s, 'square.stack.3d.up', t('This space is yours', s.lang), t('Start by turning on a module in Settings.', s.lang), [t('Choose Modules', s.lang), 'settings']);
    else content = { music, timer, calendar, todos }[s.module](s);
    body = `<div class="isl-body" style="height:${h - g.head}px">${tabs(s)}<div class="icontent">${content}</div></div>`;
  }
  return `<div class="${cls}" style="width:${w}px;height:${h}px;margin-top:${g.notch ? 0 : 8}px" data-mode="${s.mode}" lang="${s.lang === 'tr' ? 'tr' : 'en'}">${head}${body}</div>`;
}

function desk(s, opts = {}) {
  const { w, h, g } = islandSize(s);
  const width = opts.width || 760;
  const barH = g.notch ? g.head : 24;
  const height = opts.height || Math.max(h + (g.notch ? 0 : 8) + 28, barH + 40);
  const left = g.notch ? '<b></b><span>Finder</span><span>File</span><span>Edit</span><span>View</span>' : '<b></b><b>Finder</b><span>File</span><span>Edit</span><span>View</span><span>Go</span>';
  const menus = opts.bare ? '' : `<span class="menus"><b style="font-size:15px"></b>${left}</span>`;
  const status = opts.bare ? '' : `<span class="status"><span class="mb-icon" aria-label="Brimlet"></span><span>${s.lang === 'tr' ? 'Pzt 26 Eki' : 'Mon 26 Oct'}&nbsp;&nbsp;14:20</span></span>`;
  const notch = g.notch ? `<span class="notch" style="width:${g.nw}px;height:${g.head}px" aria-hidden="true"></span>` : '';
  return `<div class="desk ${opts.dark ? 'is-dark' : ''}" style="width:${width}px;height:${height}px"><div class="desk-bar" style="height:${barH}px">${menus}${status}</div>${notch}<div class="desk-stage" ${opts.stageId ? `id="${opts.stageId}"` : ''}>${island(s)}</div></div>`;
}

function quote(s) {
  const lang = s.lang; const theme = s.theme || 'dark';
  const head = (title) => `<div class="qc-h"><span class="qc-k">${sym('quote.opening')}${t(title, lang)}</span><button class="qc-x" title="${esc(t('Close', lang))}" aria-label="${esc(t('Close Quote', lang))}"${act(s, 'qclose')}>${sym('xmark')}</button></div>`;
  if (s.capture) {
    const text = s.text ?? DATA.quote.text;
    return `<div class="qc theme-${theme}" lang="${lang}">${head('Add to Brimlet as Quote')}<textarea class="qc-area" aria-label="${esc(t('Add to Brimlet as Quote', lang))}"${s.interactive ? ' data-act="qtext"' : ''}>${esc(text)}</textarea>
      <div class="qc-fields"><div class="qc-field"><label>${t('Person or author', lang)}</label><input class="sw-text" placeholder="${esc(t('Optional', lang))}" value="${esc(s.author || '')}"></div><div class="qc-field"><label>${t('Book or source', lang)}</label><input class="sw-text" placeholder="${esc(t('Optional', lang))}" value="${esc(s.source || '')}"></div></div>
      <div class="qc-f"><span>${t('Where it’s from is up to you.', lang)}</span><button class="sw-btn is-p"${text.trim() ? '' : ' disabled'}${act(s, 'qsave')}>${t('Save', lang)}</button></div></div>`;
  }
  const q = s.quote || DATA.quote;
  const by = q.author || q.source ? `<p class="qc-by">— ${esc(q.author || L(q, lang, 'source'))}${q.author && q.source ? `, <span>${esc(L(q, lang, 'source'))}</span>` : ''}</p>` : '';
  const foot = s.secs === 0 ? t('Open until you close it', lang) : t('%d s · Waits while you hover', lang, s.secs || 30);
  return `<div class="qc theme-${theme}" lang="${lang}">${head('One of your quotes')}<div class="qc-scroll" style="${s.maxH ? `max-height:${s.maxH}px` : ''}"><p class="qc-text">“${esc(L(q, lang))}”</p>${by}</div><div class="qc-f"><span>${foot}</span><button class="sw-link" style="color:var(--q-label-2)"${act(s, 'qclose')}>${t('Close', lang)}</button></div></div>`;
}

function taskSheet(s) {
  const lang = s.lang; const theme = s.theme || 'light';
  const title = s.title ?? '';
  const seg = ['home', 'personal', 'work'].map((c) => `<button role="radio" aria-checked="${(s.cat || 'home') === c}"${act(s, 'tcat', ` data-v="${c}"`)}>${t({ home: 'Home', personal: 'Personal', work: 'Work' }[c], lang)}</button>`).join('');
  const date = s.hasDate ? `<div class="ts-row" style="padding-left:2px"><span>${t('Due', lang)}</span><span class="sw-pop" style="min-width:132px"><span>${lang === 'tr' ? '28.10.2026' : '28 Oct 2026'}</span><i>${sym('chevron.updown')}</i></span></div>
    <div class="ts-row"><span class="sw-label"><span class="sw-t">${t('Remind me at 9:00 that morning', lang)}</span><span class="sw-sub">${t('macOS asks for permission the first time.', lang)}</span></span><button class="sw-switch" role="switch" aria-checked="${!!s.remind}"${act(s, 'tremind')}></button></div>` : '';
  return `<div class="ts theme-${theme}" role="dialog" aria-label="${esc(t('New Task', lang))}" lang="${lang}"><div class="ts-body"><p class="ts-title">${t('New Task', lang)}</p>
    <div class="ts-field"><input class="sw-text ${s.focus ? 'is-focus' : ''}" placeholder="${esc(t('What do you need to do?', lang))}" value="${esc(title)}" aria-label="${esc(t('What do you need to do?', lang))}"${s.interactive ? ' data-act="ttitle"' : ''}><input class="sw-text" placeholder="${esc(t('Note (optional)', lang))}" value="${esc(s.note || '')}" aria-label="${esc(t('Note (optional)', lang))}"></div>
    <div class="ts-row"><span>${t('Category', lang)}</span><div class="sw-seg" role="radiogroup" aria-label="${esc(t('Category', lang))}" style="width:${lang === 'tr' ? 210 : 200}px">${seg}</div></div>
    <div class="ts-row"><span>${t('Add a Date', lang)}</span><button class="sw-switch" role="switch" aria-checked="${!!s.hasDate}"${act(s, 'tdate')}></button></div>${date}</div>
    <div class="ts-acts"><button class="sw-btn"${act(s, 'tcancel')}>${t('Cancel', lang)}</button><button class="sw-btn is-p"${title.trim() ? '' : ' disabled'}${act(s, 'tadd')}>${t('Add', lang)}</button></div></div>`;
}

const TABS = [['general', 'General', 'gearshape'], ['modules', 'Modules', 'square.stack.3d.up'], ['calendar', 'Calendar', 'calendar'], ['notifications', 'Notifications', 'bell.badge'], ['quotes', 'Quotes', 'quote.opening']];
const swSwitch = (s, on, a, label, disabled) => `<button class="sw-switch" role="switch" aria-checked="${!!on}" aria-label="${esc(label)}"${disabled ? ' disabled' : ''}${act(s, 'sw', ` data-v="${a}"`)}></button>`;
const row = (title, sub, ctl, extra = '') => `<div class="sw-row ${extra}"><span class="sw-label"><span class="sw-t">${title}</span>${sub ? `<span class="sw-sub">${sub}</span>` : ''}</span>${ctl || ''}</div>`;
const rowWide = (title, sub, ctl) => `<div class="sw-row is-wrap"><span class="sw-label"><span class="sw-t">${title}</span></span>${ctl}<span class="sw-sub is-full">${sub}</span></div>`;
const pop = (label, disabled, w) => `<button class="sw-pop" ${w ? `style="min-width:${w}px"` : ''}${disabled ? ' disabled' : ''}><span>${esc(label)}</span><i>${sym('chevron.updown')}</i></button>`;

function updateRow(s) {
  const u = s.update || {}; const lang = s.lang;
  const icon = '<img class="sw-app" src="assets/brimlet-256.png" alt="" width="32" height="32">';
  if (['available', 'downloading', 'opening', 'failed', 'noChecksum'].includes(u.state)) {
    let sub;
    if (u.state === 'downloading') sub = `<span class="sw-progress" style="--p:${u.progress ?? .42};margin-top:5px;width:220px" role="progressbar" aria-label="${esc(t('Downloading Brimlet %@', lang, u.version))}" aria-valuenow="${Math.round((u.progress ?? .42) * 100)}"><span></span></span>`;
    else if (u.state === 'opening') sub = `<span class="sw-sub">${t('Drag Brimlet from the disk image to Applications and replace this version.', lang)}</span>`;
    else if (u.state === 'failed') sub = `<span class="sw-sub is-warn">${t('The download didn’t match its checksum and was deleted. The release page is open in your browser instead.', lang)}</span>`;
    else if (u.state === 'noChecksum') sub = `<span class="sw-sub is-warn">${t('This release has no checksum to verify the download, so its page is open in your browser instead.', lang)}</span>`;
    else sub = `<span class="sw-sub">${t('You have %@.', lang, u.current || '0.2.0')} <button class="sw-link">${t('Release Notes', lang)}</button></span>`;
    const busy = u.state === 'downloading' || u.state === 'opening';
    return `<div class="sw-row is-top">${icon}<span class="sw-label"><span class="sw-t sw-strong">${t('Brimlet %@ is available', lang, u.version || '0.2.1')}</span>${sub}</span><button class="sw-btn is-p" title="${esc(t('Downloads the disk image and opens it, then Brimlet quits so you can drag the new version to Applications.', lang))}"${busy ? ' disabled' : ''}>${t('Download and Install', lang)}</button></div>`;
  }
  let sub;
  if (u.state === 'checking') sub = `<span class="sw-sub" style="display:flex;align-items:center;gap:6px">${spin()}${t('Checking for updates…', lang)}</span>`;
  else if (u.state === 'upToDate') sub = `<span class="sw-sub">${t('This is the latest version.', lang)}</span>`;
  else if (u.state === 'checkFailed') sub = `<span class="sw-sub is-warn">${t('Couldn’t check for updates. %@', lang, t('GitHub is limiting requests. Try again later.', lang))}</span>`;
  else if (u.lastCheck) sub = `<span class="sw-sub">${t('Last checked: %@', lang, u.lastCheck)}</span>`;
  else sub = `<span class="sw-sub">${t('Not checked yet.', lang)}</span>`;
  return `<div class="sw-row">${icon}<span class="sw-label"><span class="sw-t sw-strong">${t('Brimlet %@', lang, u.current || '0.2.0')}</span>${sub}</span><button class="sw-btn"${u.state === 'checking' ? ' disabled' : ''}${act(s, 'check')}>${t('Check Now', lang)}</button></div>`;
}

function tabGeneral(s) {
  const lang = s.lang; const lg = s.login || {};
  const loginErr = lg.error === 'failed' ? `<span class="sw-sub is-warn">${t('Open at Login couldn’t be changed. Move Brimlet to Applications and try again.', lang)}</span>` : lg.error === 'approval' ? `<span class="sw-sub is-warn">${t('Allow Brimlet in System Settings › General › Login Items.', lang)}</span>` : `<span class="sw-sub">${t('Starts Brimlet when you log in.', lang)}</span>`;
  const dispLabel = s.displayMissing ? t('Chosen display isn’t connected', lang) : s.display === 'studio' ? 'Studio Display' : t('Automatic · Notched display first', lang);
  return `<section class="sw-sec"><div class="sw-box">${updateRow(s)}${row(t('Check for updates automatically', lang), t('Once a day Brimlet asks GitHub for the latest version number.', lang), swSwitch(s, (s.update || {}).auto !== false, 'auto', t('Check for updates automatically', lang)))}</div></section>
  <section class="sw-sec"><div class="sw-box"><div class="sw-row"><span class="sw-label"><span class="sw-t">${t('Open at Login', lang)}</span>${loginErr}</span>${swSwitch(s, lg.on, 'login', t('Open at Login', lang))}</div></div></section>
  <section class="sw-sec"><h3 class="sw-head">${t('On Screen', lang)}</h3><div class="sw-box">
    ${rowWide(t('Display', lang), t('If the display goes away, Brimlet moves to another one. On displays without a notch it shows as a small capsule.', lang), pop(dispLabel, false, 200))}
    ${row(t('Expand on hover', lang), t('You can also click it open.', lang), swSwitch(s, s.hover !== false, 'hover', t('Expand on hover', lang)))}
    ${row(t('Hide in full screen', lang), t('Leaves the space empty when an app fills the screen.', lang), swSwitch(s, s.fullscreen !== false, 'fullscreen', t('Hide in full screen', lang)))}</div>
    <div class="sw-foot has-btn"><p>${t('Brimlet follows the Reduce Motion setting of macOS. Click its top bar to close it, or press Esc while it has keyboard focus.', lang)}</p><button class="sw-btn"${act(s, 'show')}>${t('Show Brimlet', lang)}</button></div></section>
  <section class="sw-sec"><div style="display:flex;gap:8px;margin:0 4px"><span class="sw-ico" style="margin-top:-1px">${sym('lock.shield')}</span><div style="display:grid;gap:4px"><p class="sw-t sw-strong" style="margin:0">${t('No account, no analytics.', lang)}</p><p class="sw-sub" style="margin:0">${t('Brimlet asks for macOS Automation access only when you connect Spotify. It uses it to read the current track and control playback.', lang)} ${t('Album art comes from Spotify’s servers and lyrics from LRCLIB. There is no account and no analytics, and nothing is sent to a server of ours.', lang)}</p></div></div></section>`;
}

function tabModules(s) {
  const lang = s.lang; const md = s.mods || { order: ['music', 'timer', 'calendar', 'todos'], on: { music: true, timer: true, calendar: false, todos: true } };
  const meta = { music: ['Music', 'music.note', 'Spotify · The track and playback controls'], timer: ['Timer', 'timer', 'A short break or some focus time'], calendar: ['Calendar', 'calendar', 'Upcoming events and meeting links'], todos: ['Tasks', 'checklist', 'Keep track of home, personal and work tasks'] };
  const rows = md.order.map((id, i) => `<div class="sw-row ${s.dragRow === i ? 'is-drag' : ''}" style="${s.dragRow === i ? 'background:var(--c-fill);border-radius:10px' : ''}"><span class="sw-handle" title="${esc(t('Drag to change the order', lang))}">${sym('line.3.horizontal')}</span><span class="sw-mod">${sym(meta[id][1])}</span><span class="sw-label"><span class="sw-t">${t(meta[id][0], lang)}</span><span class="sw-sub">${t(meta[id][2], lang)}</span></span>${swSwitch(s, md.on[id], 'mod-' + id, t(meta[id][0], lang))}</div>`).join('');
  const spot = s.spotify === 'connected'
    ? `<div class="sw-row"><span class="sw-ico is-ok">${sym('checkmark.circle.fill')}</span><span class="sw-label"><span class="sw-t">${t('Connected to Spotify', lang)}</span></span><button class="sw-btn"${act(s, 'disconnect')}>${t('Disconnect', lang)}</button></div>`
    : `<div class="sw-row"><span class="sw-ico">${sym('music.note')}</span><span class="sw-label"><span class="sw-t">Spotify</span><span class="sw-sub">${md.on.music ? t('Not connected', lang) : t('Turn on Music to connect Spotify.', lang)}</span></span><button class="sw-btn is-p"${md.on.music ? '' : ' disabled'}${act(s, 'connect')}>${t('Connect to Spotify', lang)}</button></div>`;
  return `<section class="sw-sec"><h3 class="sw-head">${t('Modules', lang)}</h3><div class="sw-box">${rows}</div><div class="sw-foot"><p>${t('When several modules have something going on, the higher one wins. In the open panel, the tabs switch between them.', lang)}</p></div></section>
  <section class="sw-sec"><h3 class="sw-head">${t('Small View', lang)}</h3><div class="sw-box">${row(t('Keep music in front', lang), t('The small view always shows the music module.', lang), swSwitch(s, s.pinMusic, 'pin', t('Keep music in front', lang)))}${row(t('Show track changes', lang), t('Briefly shows the new track.', lang), swSwitch(s, s.trackAlerts !== false, 'alerts', t('Show track changes', lang)))}</div></section>
  <section class="sw-sec"><h3 class="sw-head">${t('Music', lang)}</h3><div class="sw-box">${spot}</div></section>
  <section class="sw-sec"><h3 class="sw-head">${t('Timer', lang)}</h3><div class="sw-box">${row(t('Play a sound when time’s up', lang), t('A short sound when the timer ends.', lang), swSwitch(s, s.timerSound !== false, 'sound', t('Play a sound when time’s up', lang), !md.on.timer))}</div><div class="sw-foot"><p>${t('Turning off the timer module resets a running timer.', lang)} ${t('The timer runs while Brimlet is open and ends when you quit it.', lang)}</p></div></section>`;
}

function tabCalendar(s) {
  const lang = s.lang; const c = s.cal || {}; const on = (s.mods || { on: {} }).on.calendar;
  const note = `<div class="sw-foot"><p>${t('Turning on Calendar asks macOS for access. Events are only read; your calendar is never changed.', lang)}</p></div>`;
  if (!on) return `<section class="sw-sec"><div class="sw-box"><div class="sw-row"><span class="sw-ico">${sym('calendar')}</span><span class="sw-label"><span class="sw-t">${t('Calendar is off', lang)}</span><span class="sw-sub">${t('Upcoming events and meeting links', lang)}</span></span><button class="sw-btn is-p"${act(s, 'calon')}>${t('Turn On', lang)}</button></div></div>${note}</section>`;
  if (c.access && c.access !== 'ready') {
    const denied = c.access === 'denied' || c.access === 'restricted';
    return `<section class="sw-sec"><h3 class="sw-head">${t('Access', lang)}</h3><div class="sw-box"><div class="sw-row"><span class="sw-ico ${denied ? 'is-warn' : ''}">${sym(denied ? 'exclamationmark.triangle.fill' : 'calendar')}</span><span class="sw-label"><span class="sw-t">${t(denied ? 'Calendar access is off' : 'Not requested yet', lang)}</span><span class="sw-sub">${t(denied ? (c.access === 'restricted' ? 'Calendar access is restricted on this Mac.' : 'Turn on full access in System Settings › Privacy & Security › Calendars.') : 'Allow calendar access to see your upcoming events.', lang)}</span></span>${c.access === 'restricted' ? '' : `<button class="sw-btn ${denied ? '' : 'is-p'}">${t(denied ? 'Open System Settings' : 'Connect Calendar', lang)}</button>`}</div></div>${note}</section>
    <section class="sw-sec"><h3 class="sw-head">${t('Calendars', lang)}</h3><div class="sw-box"><div class="sw-row"><span class="sw-sub" style="font-size:13px;line-height:16px">${t('Your calendars appear here once Brimlet has access.', lang)}</span></div></div></section>`;
  }
  const sel = c.sel || { c1: true, c2: true, c3: true, c4: true, c5: true };
  const all = c.all !== false;
  const none = !all && !Object.values(sel).some(Boolean);
  let lastAcc = '';
  const list = DATA.calendars.map((cal) => {
    const head = cal.account !== lastAcc ? `<div class="sw-row" style="min-height:26px;padding-top:8px;padding-bottom:2px"><span class="sw-sub" style="font-weight:600">${esc(cal.account === 'Other' ? (lang === 'tr' ? 'Diğer' : 'Other') : cal.account)}</span></div>` : '';
    lastAcc = cal.account;
    const on2 = all || sel[cal.id];
    return `${head}<div class="sw-row is-sub" style="min-height:30px"><button class="sw-check" role="checkbox" aria-checked="${!!on2}" aria-label="${esc(L(cal, lang))}"${act(s, 'cal', ` data-v="${cal.id}"`)}>${sym('checkmark')}</button><span class="cdot" style="--c:var(--cal-${cal.color})"></span><span class="sw-t">${esc(L(cal, lang))}</span></div>`;
  }).join('');
  return `<section class="sw-sec"><div class="sw-box">${rowWide(t('Event reminder', lang), t('Shows a short reminder while Brimlet is open and visible. Not for all-day events.', lang), pop(t({ 0: 'Off', 5: '5 minutes before', 10: '10 minutes before' }[c.reminder ?? 5], lang), false, 160))}</div></section>
  <section class="sw-sec"><h3 class="sw-head">${t('Calendars', lang)}</h3><div class="sw-box">${row(t('All Calendars', lang), '', swSwitch(s, all, 'allcal', t('All Calendars', lang)))}${list}</div>${none ? `<div class="sw-foot"><span class="sw-ico is-warn" style="width:14px;height:14px">${sym('exclamationmark.triangle.fill')}</span><p style="color:var(--c-warning)">${t('No calendar is selected, so no events or reminders are shown.', lang)}</p></div>` : note}</section>`;
}

function tabNotifications(s) {
  const lang = s.lang; const n = s.notif || {};
  const apps = n.apps || [{ name: 'Reminders example', id: 'com.example.reminders' }];
  const list = apps.length ? apps.map((a) => `<div class="sw-row"><img class="sw-app is-small" src="assets/app-terminal.png" alt="" width="24" height="24"><span class="sw-label"><span class="sw-t">${esc(a.name)}</span><span class="sw-sub">${esc(a.id)}</span></span><button class="sw-btn"${act(s, 'rmapp')}>${t('Remove', lang)}</button></div>`).join('') : `<div class="sw-row"><span class="sw-t" style="color:var(--c-label-2)">${t('No apps allowed yet', lang)}</span></div>`;
  const err = n.error === 'signature' ? 'The app’s signature couldn’t be verified. Choose a signed app.' : n.error === 'receiver' ? 'Notifications from other apps couldn’t be started. Try reopening Brimlet.' : null;
  const errRow = err ? `<div class="sw-row"><span class="sw-ico is-warn">${sym('exclamationmark.triangle.fill')}</span><span class="sw-sub is-warn" style="font-size:12px;line-height:15px">${t(err, lang)}</span></div>` : '';
  const cmux = s.cmuxInstalled === false ? '' : `<section class="sw-sec"><h3 class="sw-head">cmux</h3><div class="sw-box">${row(t('Show cmux sessions', lang), t('Checks every 5 seconds for sessions waiting for your reply and opens them in cmux.', lang), swSwitch(s, s.cmux, 'cmux', t('Show cmux sessions', lang)))}</div></section>`;
  return `<section class="sw-sec"><h3 class="sw-head">${t('Notifications from other apps', lang)}</h3><div class="sw-box">${list}${errRow}</div><div class="sw-foot has-btn"><p>${t('Apps you allow can show short notifications in Brimlet.', lang)}</p><button class="sw-btn"${act(s, 'addapp')}>${t('Allow an App…', lang)}</button></div></section>${cmux}`;
}

function tabQuotes(s) {
  const lang = s.lang; const q = s.quotes || {}; const on = q.on !== false;
  const iv = { 15: 'Every 15 minutes', 30: 'Every 30 minutes', 60: 'Every hour', 120: 'Every 2 hours', 360: 'Every 6 hours', 720: 'Every 12 hours', 1440: 'Once a day', 2880: 'Every 2 days' }[q.interval || 1440];
  const du = { 10: '10 seconds', 15: '15 seconds', 30: '30 seconds', 60: '1 minute', 120: '2 minutes', 0: 'Until I close it' }[q.secs ?? 30];
  const list = q.list || DATA.quotes;
  const items = list.length ? list.map((x) => `<div class="sw-row is-top"><span class="sw-label"><span class="sw-serif" style="display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:3;overflow:hidden">“${esc(L(x, lang))}”</span>${x.author || x.source ? `<span class="sw-sub">${esc([x.author, L(x, lang, 'source')].filter(Boolean).join(' · '))}</span>` : ''}</span><button class="sw-icon-btn" title="${esc(t('Delete Quote', lang))}" aria-label="${esc(t('Delete Quote', lang))}"${act(s, 'delquote')}>${sym('trash')}</button></div>`).join('') : `<div class="sw-row is-top"><span class="sw-ico">${sym('info.circle')}</span><span class="sw-sub" style="font-size:12px;line-height:16px">${t('Select some text in a PDF or a web page, Control-click it and choose Services › Add to Brimlet as Quote.', lang)}</span></div>`;
  return `<section class="sw-sec"><div class="sw-box">${row(t('Show a quote now and then', lang), t('The card slides in from the right edge and leaves the modules alone.', lang), swSwitch(s, on, 'quotes', t('Show a quote now and then', lang)))}${row(t('How often?', lang), '', pop(t(iv, lang), !on, 150))}${row(t('Stays on screen for', lang), '', pop(t(du, lang), false, 150))}</div><div class="sw-foot"><p>${t('The card stays while the pointer is on it. Close it any time with ×.', lang)}</p></div></section>
  <section class="sw-sec"><h3 class="sw-head">${t('Saved Quotes', lang)} <span class="sw-count">${list.length}</span><span class="grow"></span>${list.length ? `<button class="sw-btn" style="font-weight:400"${act(s, 'shownow')}>${t('Show Now', lang)}</button>` : ''}</h3><div class="sw-box">${items}</div><div class="sw-foot"><p>${t('Your quotes are kept on this Mac. Quotes you haven’t seen yet come first.', lang)}</p></div></section>`;
}

function settings(s) {
  const lang = s.lang; const tab = s.tab || 'general';
  const title = t(TABS.find((x) => x[0] === tab)[1], lang);
  const tabsHtml = TABS.map(([id, label, icon]) => `<button class="sw-tab" role="tab" aria-selected="${tab === id}"${act(s, 'swtab', ` data-v="${id}"`)}>${sym(icon)}<span>${t(label, lang)}</span></button>`).join('');
  const body = { general: tabGeneral, modules: tabModules, calendar: tabCalendar, notifications: tabNotifications, quotes: tabQuotes }[tab](s);
  return `<div class="sw theme-${s.theme || 'light'}" lang="${lang}" style="${s.width ? `--w:${s.width}px` : ''}"><div class="sw-top"><div class="sw-bar"><span class="sw-lights" aria-hidden="true"><i class="l-close"></i><i class="l-min"></i><i></i></span><span class="sw-title">${title}</span><span></span></div><div class="sw-tabs" role="tablist" aria-label="${esc(t('Settings', lang))}">${tabsHtml}</div></div><div class="sw-body ${s.maxH ? 'is-scroll' : ''}" style="${s.maxH ? `max-height:${s.maxH}px` : ''}" role="tabpanel">${body}</div></div>`;
}

function menu(s) {
  const lang = s.lang; const theme = s.theme || 'light';
  const it = (l, k, hi) => `<div class="mnu-i ${hi ? 'is-hi' : ''}"><span>${l}</span>${k ? `<kbd>${k}</kbd>` : ''}</div>`;
  return `<div class="mnu theme-${theme}" role="menu">${s.update ? it(t('Update to %@…', lang, '0.2.1'), '', true) + '<div class="mnu-sep"></div>' : ''}${it(t('Open Brimlet', lang), '⌘O')}${it(t('Show or Hide', lang), '⌘H')}<div class="mnu-sep"></div>${it(t('Settings…', lang), '⌘,')}${it(t('Check for Updates…', lang))}<div class="mnu-sep"></div>${it(t('Quit Brimlet', lang), '⌘Q')}</div>`;
}

window.BUI = { SYM, sym, spin, esc, t, TR, DATA, fmt, geo, islandSize, island, desk, quote, taskSheet, settings, menu, TABS };
})();
