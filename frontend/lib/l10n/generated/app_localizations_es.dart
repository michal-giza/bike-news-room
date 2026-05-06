// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'Las noticias de hoy';

  @override
  String get updatedJustNow => 'ACTUALIZADO AHORA MISMO';

  @override
  String updatedMinutesAgo(int minutes) {
    return 'ACTUALIZADO HACE $minutes MIN';
  }

  @override
  String updatedHoursAgo(int hours) {
    return 'ACTUALIZADO HACE $hours H';
  }

  @override
  String updatedDaysAgo(int days) {
    return 'ACTUALIZADO HACE $days D';
  }

  @override
  String storiesCount(int count) {
    return '$count HISTORIAS';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NUEVAS DESDE TU ÚLTIMA VISITA';
  }

  @override
  String get scrollForMore => 'DESPLÁZATE PARA VER MÁS';

  @override
  String get endOfFeed => '— FIN DEL FEED —';

  @override
  String get live => 'EN DIRECTO';

  @override
  String get couldNotReachNewsRoom =>
      'No se ha podido conectar con la sala de redacción';

  @override
  String get retry => 'Reintentar';

  @override
  String get noArticlesMatch =>
      'No hay artículos que coincidan con estos filtros';

  @override
  String get tryBroadeningFilters => 'Prueba a ampliar o limpiar los filtros.';

  @override
  String couldntLoadMore(String error) {
    return 'No se pudo cargar más: $error';
  }

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabSearch => 'Buscar';

  @override
  String get tabBookmarks => 'Guardados';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabFollowing => 'Siguiendo';

  @override
  String get search => 'Buscar';

  @override
  String get searchPlaceholderShort => 'Buscar…';

  @override
  String get searchPlaceholderLong => 'Busca carreras, corredores, equipos…';

  @override
  String get settings => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsCardDensity => 'Densidad de tarjetas';

  @override
  String get settingsDensityCompact => 'Compacta';

  @override
  String get settingsDensityComfort => 'Estándar';

  @override
  String get settingsDensityLarge => 'Amplia';

  @override
  String get settingsReducedMotion => 'Movimiento reducido';

  @override
  String get settingsReducedMotionDesc =>
      'Omitir animaciones sutiles y efectos de brillo.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsTitle => 'Alertas de noticias';

  @override
  String get settingsNotificationsDesc =>
      'Notificaciones discretas en el dispositivo cuando llegan novedades de las disciplinas que sigues. Sin cuenta, sin enviar datos.';

  @override
  String get settingsNotificationsTopicsLabel => 'DISCIPLINAS';

  @override
  String get settingsNotificationsDeliveryLabel => 'ENTREGA';

  @override
  String get settingsNotificationsDeliveryInstant => 'Instantáneo';

  @override
  String get settingsNotificationsDeliveryDaily => 'Resumen diario';

  @override
  String get settingsHiddenKeywordsLabel => 'OCULTAR PALABRAS';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Las noticias cuyo título o descripción contengan alguna de estas palabras se ocultarán del feed y de las notificaciones.';

  @override
  String get settingsHiddenKeywordsHint => 'Añadir palabra a ocultar…';

  @override
  String get raceCardAddToCalendar => 'Añadir al calendario';

  @override
  String get raceCardCalendarExportFailed =>
      'No se pudo exportar al calendario.';

  @override
  String get settingsYourData => 'Tus datos';

  @override
  String get settingsExportBookmarks => 'Exportar guardados';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count guardados · copiados como JSON';
  }

  @override
  String get settingsRedoOnboarding => 'Repetir introducción';

  @override
  String get settingsRedoOnboardingDesc =>
      'Vuelve a elegir regiones y disciplinas.';

  @override
  String get settingsRedoOnboardingDialogTitle => '¿Repetir la introducción?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'Volveremos a guiarte por la selección de regiones, disciplinas y densidad de tarjetas. Tus guardados y seguimiento se conservarán.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get redo => 'Repetir';

  @override
  String settingsBookmarksCopied(int count) {
    return 'Copiados $count guardados al portapapeles.';
  }

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsAboutApp => 'Acerca de Bike News Room';

  @override
  String get settingsPrivacy => 'Política de privacidad';

  @override
  String get settingsTerms => 'Términos del servicio';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Copiar enlace';

  @override
  String get shareNative => 'Compartir';

  @override
  String get shareLinkCopied => 'Enlace copiado al portapapeles.';

  @override
  String get shareTwitter => 'Compartir en X';

  @override
  String get shareBluesky => 'Compartir en Bluesky';

  @override
  String get shareWhatsApp => 'Compartir en WhatsApp';

  @override
  String get shareReddit => 'Compartir en Reddit';

  @override
  String get shareTelegram => 'Compartir en Telegram';

  @override
  String get alsoCoveredBy => 'TAMBIÉN LO CUBREN';

  @override
  String readOnSource(String source) {
    return 'Leer en $source';
  }

  @override
  String get summary => 'RESUMEN';

  @override
  String get digestHeadline => 'Noticias ciclistas, cada mañana a las 7.';

  @override
  String get digestSubheadline =>
      'Un correo. Las historias más importantes del día. Sin anuncios, sin spam, te das de baja con un clic.';

  @override
  String get digestEmailHint => 'tu@ejemplo.com';

  @override
  String get digestSubscribe => 'SUSCRIBIRME';

  @override
  String get digestInvalidEmail => 'Eso no parece un correo electrónico.';

  @override
  String get digestNetworkError =>
      'No se ha podido conectar con la sala de redacción. Inténtalo en un minuto.';

  @override
  String get digestGenericError => 'Algo ha ido mal. Inténtalo de nuevo.';

  @override
  String get digestSuccess =>
      'Revisa tu bandeja de entrada — confirma para empezar a recibir el resumen.';

  @override
  String get digestPrivacyPrefix => 'Al suscribirte aceptas nuestra ';

  @override
  String get digestPrivacyLink => 'política de privacidad';

  @override
  String get digestPrivacySuffix => '. Cancela cuando quieras.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'PASO $current / $total';
  }

  @override
  String get onboardingStepRegions => 'REGIONES';

  @override
  String get onboardingStepDisciplines => 'DISCIPLINAS';

  @override
  String get onboardingStepDensity => 'DENSIDAD';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingFinish => 'Llévame al feed';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get calendarFilterAll => 'TODOS';

  @override
  String get calendarEmpty => 'Aún no hay carreras próximas';

  @override
  String get calendarError => 'No se ha podido cargar el calendario';

  @override
  String get raceCardToday => 'HOY';

  @override
  String get raceCardNow => 'AHORA';

  @override
  String get raceCardTomorrow => 'MAÑANA';

  @override
  String raceCardDays(int days) {
    return '$days D';
  }

  @override
  String get tooltipBookmark => 'Guardar';

  @override
  String get tooltipClose => 'Cerrar';

  @override
  String get tooltipUnfollow => 'Dejar de seguir';

  @override
  String get shareLinkCopiedShort => 'Enlace copiado';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'Más…';

  @override
  String get follow => '+ SEGUIR';

  @override
  String followingName(String name) {
    return 'Siguiendo a $name';
  }

  @override
  String get searchHint => 'Busca artículos, corredores, carreras…';

  @override
  String get searchAddSourceTitle => '¿No encuentras lo que buscas?';

  @override
  String get searchAddSourceBody =>
      'Pega cualquier feed RSS o sitio web para añadirlo como fuente.';

  @override
  String get searchKeyToSearch => 'para buscar';

  @override
  String get searchKeyToClose => 'para cerrar';

  @override
  String get breakingHeader => 'ÚLTIMA HORA · ÚLTIMA HORA';

  @override
  String get regionWorld => '🌍 Mundo';

  @override
  String get regionEu => '🇪🇺 UE';

  @override
  String get regionPoland => '🇵🇱 Polonia';

  @override
  String get regionSpain => '🇪🇸 España';

  @override
  String get disciplineAll => 'Todas';

  @override
  String get disciplineRoad => 'Ruta';

  @override
  String get disciplineMtb => 'MTB';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Pista';

  @override
  String get disciplineCx => 'Ciclocross';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'ÚLTIMA ACTUALIZACIÓN · $date';
  }

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutH1 => 'Qué es';

  @override
  String get aboutB1 =>
      'Bike News Room es un único feed con noticias de ciclismo de todo el mundo: ruta, MTB, gravel, pista y ciclocross. Agregamos desde feeds RSS públicos y webs de publicaciones, federaciones y blogs independientes, para que dejes de saltar entre veinte pestañas para estar al día.';

  @override
  String get aboutH2 => 'Cómo funciona';

  @override
  String get aboutB2 =>
      'Cada 30 minutos nuestro backend extrae datos de las fuentes configuradas, deduplica historias casi idénticas, las clasifica por región y disciplina y las añade al feed que estás leyendo. Cualquiera puede añadir una fuente mediante el formulario «Añadir una fuente», y mostramos automáticamente los dominios que vemos citados con frecuencia para revisión.';

  @override
  String get aboutH3 => 'Sin muros de pago, sin trampas algorítmicas';

  @override
  String get aboutB3 =>
      'No ordenamos por engagement, no te seguimos entre sitios y no vendemos nada. El orden es cronológico inverso, con filtros por región y disciplina que tú controlas. Si una historia está aquí es porque una publicación ciclista la ha publicado.';

  @override
  String get aboutH4 => 'Código abierto';

  @override
  String get aboutB4 =>
      'Todo el código fuente (backend en Rust + frontend Flutter Web) está en GitHub. ¿Has encontrado un error, quieres añadir una fuente o forkearlo para otro deporte? Pull requests bienvenidos.';

  @override
  String get privacyTitle => 'Política de privacidad';

  @override
  String get privacyH1 => 'Qué recopilamos';

  @override
  String get privacyB1 =>
      'Casi nada. El frontend guarda tus preferencias (tema, filtros, guardados, último artículo visto) en el almacenamiento local de tu navegador — nunca salen de tu dispositivo. Si te suscribes al resumen diario, guardamos tu correo y un token de confirmación/baja en nuestra base de datos; eso es todo.';

  @override
  String get privacyH2 => 'Qué no recopilamos';

  @override
  String get privacyB2 =>
      'Nada de SDK de analítica, ni rastreadores de terceros, ni cookies publicitarias, ni huella digital, ni registro de IP más allá de los logs estándar del servidor (rotados semanalmente), ni perfil de tus hábitos de lectura.';

  @override
  String get privacyH3 => 'Resumen por correo';

  @override
  String get privacyB3 =>
      'Si te suscribes, tu correo se usa únicamente para enviarte el resumen diario. Usamos Resend para entregarlo: ven la dirección al entregar el correo pero no la usan para nada más. Puedes darte de baja con un clic desde cualquier correo; una vez dado de baja, la dirección permanece en la base (marcada como tal) para que no pueda volver a suscribirla un tercero hasta que vuelvas a confirmar.';

  @override
  String get privacyH4 => 'Cookies';

  @override
  String get privacyB4 =>
      'No usamos cookies. El almacenamiento local del navegador se usa para tus preferencias — borrar los datos del sitio las elimina.';

  @override
  String get privacyH5 => 'Tus datos, tu decisión';

  @override
  String get privacyB5 =>
      'Escríbenos a hello@bike-news-room y eliminaremos cualquier registro de suscripción que nos pidas. No hay nada más que borrar porque no hay nada más almacenado.';

  @override
  String get termsTitle => 'Términos del servicio';

  @override
  String get termsH1 => 'Uso del servicio';

  @override
  String get termsB1 =>
      'Bike News Room es un agregador de noticias gratuito y público. Puedes usarlo para lectura personal y no comercial. No intentes scrapear la API a alta frecuencia — hay límite de tasa por IP y te devolveremos un 429 sin dudarlo. Si necesitas acceso masivo, el código es abierto; despliega tu propia instancia.';

  @override
  String get termsH2 => 'Contenido de los artículos';

  @override
  String get termsB2 =>
      'Titulares, fragmentos y enlaces mostrados en el feed proceden de feeds RSS públicos y páginas de publicaciones ciclistas. El tráfico de clics va al editor original. No reproducimos artículos completos — léelos siempre en la web de origen para apoyar a quienes los reportan.';

  @override
  String get termsH3 => 'Sin garantía';

  @override
  String get termsB3 =>
      'El servicio se ofrece «tal cual». Los artículos pueden contener errores (no verificamos los hechos de las publicaciones que agregamos). No lo uses como única fuente para decisiones de carrera, negociaciones contractuales ni nada donde equivocarse tenga un coste real.';

  @override
  String get termsH4 => 'Añadir fuentes';

  @override
  String get termsB4 =>
      'Cualquiera puede enviar una URL de fuente. Hacemos comprobaciones automáticas de seguridad (URL guard, límites de tamaño, sondeo de contenido) pero nos reservamos el derecho de retirar fuentes que resulten ser spam, fuera de tema o de baja calidad.';

  @override
  String get termsH5 => 'Cambios';

  @override
  String get termsB5 =>
      'Podemos actualizar estos términos ocasionalmente. Los cambios materiales se anunciarán en el resumen diario antes de entrar en vigor.';

  @override
  String get onbRegionsTitle => '¿En qué se debe centrar el feed?';

  @override
  String get onbRegionsSub =>
      'Siempre verás carreras globales. Elige qué regiones reciben peso extra.';

  @override
  String get onbDisciplinesTitle => '¿Qué bicicletas te enganchan?';

  @override
  String get onbDisciplinesSub =>
      'Marca todas las que apliquen — las usamos para etiquetar por color y priorizar historias.';

  @override
  String get onbDensityTitle => '¿Cómo de denso quieres el feed?';

  @override
  String get onbDensitySub =>
      'Puedes cambiarlo en cualquier momento desde el feed.';

  @override
  String get onbCompactSub =>
      'Máximo de historias. Filas de lista, sin imágenes.';

  @override
  String get onbComfortSub => 'Equilibrado. Imagen + cuerpo.';

  @override
  String get onbLargeSub => 'Tarjetas editoriales destacadas.';

  @override
  String get nameWorld => 'Mundo';

  @override
  String get nameEu => 'UE';

  @override
  String get namePoland => 'Polonia';

  @override
  String get nameSpain => 'España';

  @override
  String get descWorld => 'Todo, en todas partes.';

  @override
  String get descEu => 'Foco en el ciclismo europeo.';

  @override
  String get descPoland => 'Carreras y corredores de PL.';

  @override
  String get descSpain => 'Carreras y corredores de ES.';

  @override
  String get disciplineCxLong => 'Ciclocross';

  @override
  String get descRoad => 'General, clásicas, sprints.';

  @override
  String get descMtb => 'XC, DH, enduro, freeride.';

  @override
  String get descGravel => 'Larga distancia fuera del asfalto.';

  @override
  String get descTrack => 'Carreras en velódromo.';

  @override
  String get descCx => 'Barro, arena, vallas.';

  @override
  String get descBmx => 'Carrera y freestyle.';
}
