// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Bike News Room';

  @override
  String get todaysWire => 'As notícias de hoje';

  @override
  String get updatedJustNow => 'ATUALIZADO AGORA MESMO';

  @override
  String updatedMinutesAgo(int minutes) {
    return 'ATUALIZADO HÁ $minutes MIN';
  }

  @override
  String updatedHoursAgo(int hours) {
    return 'ATUALIZADO HÁ $hours H';
  }

  @override
  String updatedDaysAgo(int days) {
    return 'ATUALIZADO HÁ $days D';
  }

  @override
  String storiesCount(int count) {
    return '$count HISTÓRIAS';
  }

  @override
  String newSinceLastVisit(int count) {
    return '$count NOVAS DESDE A SUA ÚLTIMA VISITA';
  }

  @override
  String get scrollForMore => 'DESLIZE PARA VER MAIS';

  @override
  String get endOfFeed => '— FIM DO FEED —';

  @override
  String get live => 'AO VIVO';

  @override
  String get couldNotReachNewsRoom => 'Não foi possível contactar a redação';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get noArticlesMatch => 'Nenhum artigo corresponde a estes filtros';

  @override
  String get tryBroadeningFilters => 'Tente ampliar ou limpar os filtros.';

  @override
  String couldntLoadMore(String error) {
    return 'Não foi possível carregar mais: $error';
  }

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabSearch => 'Pesquisar';

  @override
  String get tabBookmarks => 'Guardados';

  @override
  String get tabCalendar => 'Calendário';

  @override
  String get tabFollowing => 'A seguir';

  @override
  String get search => 'Pesquisar';

  @override
  String get searchPlaceholderShort => 'Pesquisar…';

  @override
  String get searchPlaceholderLong => 'Pesquisar corridas, ciclistas, equipas…';

  @override
  String get settings => 'Definições';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsCardDensity => 'Densidade dos cartões';

  @override
  String get settingsDensityCompact => 'Compacta';

  @override
  String get settingsDensityComfort => 'Padrão';

  @override
  String get settingsDensityLarge => 'Grande';

  @override
  String get settingsReducedMotion => 'Movimento reduzido';

  @override
  String get settingsReducedMotionDesc =>
      'Saltar animações subtis e efeitos de brilho.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsNotificationsTitle => 'Alertas de notícias';

  @override
  String get settingsNotificationsDesc =>
      'Notificações discretas no dispositivo quando há novos artigos das disciplinas que segues. Sem conta, sem dados enviados.';

  @override
  String get settingsNotificationsTopicsLabel => 'DISCIPLINAS';

  @override
  String get settingsNotificationsDeliveryLabel => 'ENTREGA';

  @override
  String get settingsNotificationsDeliveryInstant => 'Instantâneo';

  @override
  String get settingsNotificationsDeliveryDaily => 'Resumo diário';

  @override
  String get settingsHiddenKeywordsLabel => 'OCULTAR PALAVRAS';

  @override
  String get settingsHiddenKeywordsDesc =>
      'Os artigos cujo título ou descrição contenham qualquer destas palavras são ocultados do feed e das notificações.';

  @override
  String get settingsHiddenKeywordsHint => 'Adicionar palavra a ocultar…';

  @override
  String get trendingHeader => 'EM ALTA';

  @override
  String get readerModeRead => 'Ler no app';

  @override
  String get readerModeHide => 'Ocultar leitor';

  @override
  String get readerModeUnavailable =>
      'Modo leitor indisponível para este artigo (o editor optou por não permitir).';

  @override
  String get readerModeError => 'Não foi possível carregar o artigo.';

  @override
  String get wikiSourceLink => 'Mais na Wikipédia';

  @override
  String get raceCardAddToCalendar => 'Adicionar ao calendário';

  @override
  String get raceCardCalendarExportFailed =>
      'Falha ao exportar para o calendário.';

  @override
  String get settingsYourData => 'Os seus dados';

  @override
  String get settingsExportBookmarks => 'Exportar guardados';

  @override
  String settingsExportBookmarksDesc(int count) {
    return '$count guardados · copiados como JSON';
  }

  @override
  String get settingsRedoOnboarding => 'Repetir introdução';

  @override
  String get settingsRedoOnboardingDesc =>
      'Volte a escolher regiões e disciplinas.';

  @override
  String get settingsRedoOnboardingDialogTitle => 'Repetir a introdução?';

  @override
  String get settingsRedoOnboardingDialogBody =>
      'Vamos guiá-lo novamente pela escolha de regiões, disciplinas e densidade. Os seus guardados e seguidos mantêm-se.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get redo => 'Repetir';

  @override
  String settingsBookmarksCopied(int count) {
    return '$count guardados copiados para a área de transferência.';
  }

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsAboutApp => 'Sobre o Bike News Room';

  @override
  String get settingsPrivacy => 'Política de privacidade';

  @override
  String get settingsTerms => 'Termos de serviço';

  @override
  String settingsVersionLine(String version) {
    return 'BIKE NEWS ROOM · v$version';
  }

  @override
  String get shareCopy => 'Copiar ligação';

  @override
  String get shareNative => 'Partilhar';

  @override
  String get shareLinkCopied => 'Ligação copiada para a área de transferência.';

  @override
  String get shareTwitter => 'Partilhar no X';

  @override
  String get shareBluesky => 'Partilhar no Bluesky';

  @override
  String get shareWhatsApp => 'Partilhar no WhatsApp';

  @override
  String get shareReddit => 'Partilhar no Reddit';

  @override
  String get shareTelegram => 'Partilhar no Telegram';

  @override
  String get alsoCoveredBy => 'TAMBÉM NOTICIADO POR';

  @override
  String readOnSource(String source) {
    return 'Ler em $source';
  }

  @override
  String get summary => 'RESUMO';

  @override
  String get digestHeadline => 'Notícias de ciclismo, todas as manhãs às 7.';

  @override
  String get digestSubheadline =>
      'Um e-mail. As histórias mais importantes do dia. Sem anúncios, sem spam, cancele com um clique.';

  @override
  String get digestEmailHint => 'voce@exemplo.com';

  @override
  String get digestSubscribe => 'SUBSCREVER';

  @override
  String get digestInvalidEmail => 'Isto não parece um e-mail.';

  @override
  String get digestNetworkError =>
      'Não foi possível contactar a redação. Tente novamente daqui a um minuto.';

  @override
  String get digestGenericError => 'Algo correu mal. Tente novamente.';

  @override
  String get digestSuccess =>
      'Verifique a caixa de entrada — confirme para começar a receber o resumo.';

  @override
  String get digestPrivacyPrefix => 'Ao subscrever aceita a nossa ';

  @override
  String get digestPrivacyLink => 'política de privacidade';

  @override
  String get digestPrivacySuffix => '. Cancele quando quiser.';

  @override
  String onboardingStepCounter(int current, int total) {
    return 'PASSO $current / $total';
  }

  @override
  String get onboardingStepRegions => 'REGIÕES';

  @override
  String get onboardingStepDisciplines => 'DISCIPLINAS';

  @override
  String get onboardingStepDensity => 'DENSIDADE';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingFinish => 'Mostrar o feed';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get calendarFilterAll => 'TODAS';

  @override
  String get calendarEmpty => 'Sem corridas próximas por agora';

  @override
  String get calendarError => 'Não foi possível carregar o calendário';

  @override
  String get raceCardToday => 'HOJE';

  @override
  String get raceCardNow => 'AGORA';

  @override
  String get raceCardTomorrow => 'AMANHÃ';

  @override
  String raceCardDays(int days) {
    return '${days}D';
  }

  @override
  String get tooltipBookmark => 'Guardar';

  @override
  String get tooltipClose => 'Fechar';

  @override
  String get tooltipUnfollow => 'Deixar de seguir';

  @override
  String get shareLinkCopiedShort => 'Ligação copiada';

  @override
  String get shareXTwitter => 'X / Twitter';

  @override
  String get shareMore => 'Mais…';

  @override
  String get follow => '+ SEGUIR';

  @override
  String followingName(String name) {
    return 'A seguir $name';
  }

  @override
  String get searchHint => 'Pesquise artigos, ciclistas, corridas…';

  @override
  String get searchAddSourceTitle => 'Não encontra o que procura?';

  @override
  String get searchAddSourceBody =>
      'Cole qualquer feed RSS ou site para o adicionar como fonte.';

  @override
  String get searchKeyToSearch => 'para pesquisar';

  @override
  String get searchKeyToClose => 'para fechar';

  @override
  String get breakingHeader => 'ÚLTIMA HORA · ÚLTIMA HORA';

  @override
  String get regionWorld => '🌍 Mundo';

  @override
  String get regionEu => '🇪🇺 UE';

  @override
  String get regionPoland => '🇵🇱 Polónia';

  @override
  String get regionSpain => '🇪🇸 Espanha';

  @override
  String get disciplineAll => 'Todas';

  @override
  String get disciplineRoad => 'Estrada';

  @override
  String get disciplineMtb => 'BTT';

  @override
  String get disciplineGravel => 'Gravel';

  @override
  String get disciplineTrack => 'Pista';

  @override
  String get disciplineCx => 'Ciclocrosse';

  @override
  String get disciplineBmx => 'BMX';

  @override
  String infoLastUpdated(String date) {
    return 'ATUALIZADO PELA ÚLTIMA VEZ · $date';
  }

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutH1 => 'O que é';

  @override
  String get aboutB1 =>
      'O Bike News Room é um único feed de notícias de ciclismo de todo o mundo — estrada, BTT, gravel, pista e ciclocrosse. Agregamos feeds RSS públicos e sites de publicações ciclistas, federações e blogues independentes, para que deixe de saltar entre vinte separadores para se manter a par.';

  @override
  String get aboutH2 => 'Como funciona';

  @override
  String get aboutB2 =>
      'A cada 30 minutos o nosso backend recolhe das fontes configuradas, deduplica histórias quase idênticas, classifica por região e disciplina e adiciona-as ao feed que está a ler. Qualquer pessoa pode adicionar uma fonte através do formulário \"Adicionar fonte\", e mostramos automaticamente domínios frequentemente citados em artigos para revisão.';

  @override
  String get aboutH3 => 'Sem paywall, sem jogos de algoritmo';

  @override
  String get aboutB3 =>
      'Não ordenamos por interação, não o seguimos entre sites e não vendemos nada. A ordem é cronológica inversa, com filtros por região e disciplina que controla. Se uma história está aqui é porque uma publicação ciclista a publicou de facto.';

  @override
  String get aboutH4 => 'Projeto independente';

  @override
  String get aboutB4 =>
      'O Bike News Room é desenvolvido de forma independente. Sem acordos com editoras — cada artigo vem de feeds RSS públicos que agregamos com transparência.';

  @override
  String get privacyTitle => 'Política de privacidade';

  @override
  String get privacyH1 => 'O que recolhemos';

  @override
  String get privacyB1 =>
      'Quase nada. O frontend guarda as suas preferências (tema, filtros, guardados, último artigo visto) no armazenamento local do navegador — nunca saem do seu dispositivo. Se subscrever o resumo diário, guardamos o endereço de e-mail e um token de confirmação/cancelamento na nossa base de dados; é tudo.';

  @override
  String get privacyH2 => 'O que não recolhemos';

  @override
  String get privacyB2 =>
      'Sem SDKs de analítica, sem rastreadores de terceiros, sem cookies publicitários, sem fingerprinting, sem registo de IP além dos logs padrão do servidor (rotativos semanalmente), sem perfil dos seus hábitos de leitura.';

  @override
  String get privacyH3 => 'Resumo por e-mail';

  @override
  String get privacyB3 =>
      'Se subscrever, o seu e-mail é usado apenas para enviar o resumo diário. Usamos o Resend para entrega — eles veem o endereço durante o envio mas não o utilizam para mais nada. Pode cancelar com um clique a partir de qualquer e-mail; após o cancelamento, o endereço fica na base (marcado como tal) para que não possa ser reinscrito por terceiros até o reconfirmar.';

  @override
  String get privacyH4 => 'Cookies';

  @override
  String get privacyB4 =>
      'Não definimos cookies. O armazenamento local do navegador é usado para as suas preferências — apagar dados do site elimina-as.';

  @override
  String get privacyH5 => 'Os seus dados, a sua escolha';

  @override
  String get privacyB5 =>
      'Envie-nos um e-mail para hello@bike-news-room e apagaremos qualquer registo de subscrição que solicite. Não há mais nada para apagar porque não armazenamos mais nada.';

  @override
  String get termsTitle => 'Termos de serviço';

  @override
  String get termsH1 => 'Uso do serviço';

  @override
  String get termsB1 =>
      'O Bike News Room é um agregador de notícias gratuito para uso pessoal. Não tentes fazer scraping da API em volume — há um limite por IP e responderemos com 429. O uso massivo ou comercial da API requer autorização por escrito.';

  @override
  String get termsH2 => 'Conteúdo dos artigos';

  @override
  String get termsB2 =>
      'Cabeçalhos, excertos e ligações exibidos no feed provêm de feeds RSS públicos e páginas de publicações ciclistas. O tráfego dos cliques vai para o editor original. Não reproduzimos artigos completos — leia sempre no site original para apoiar quem faz o jornalismo.';

  @override
  String get termsH3 => 'Sem garantia';

  @override
  String get termsB3 =>
      'O serviço é fornecido tal como está. Os artigos podem conter imprecisões (não verificamos os factos das publicações que agregamos). Não use isto como única fonte para decisões em dia de corrida, negociações de contratos ou qualquer coisa onde errar tenha custo real.';

  @override
  String get termsH4 => 'Adicionar fontes';

  @override
  String get termsB4 =>
      'Qualquer pessoa pode submeter um URL de fonte. Fazemos verificações automáticas de segurança (URL guard, limites de payload, sondagem de conteúdo) mas reservamos o direito de remover fontes que se revelem spam, fora do tema ou de baixa qualidade.';

  @override
  String get termsH5 => 'Alterações';

  @override
  String get termsB5 =>
      'Podemos atualizar estes termos ocasionalmente. Alterações materiais serão sinalizadas no resumo diário antes de entrarem em vigor.';

  @override
  String get onbRegionsTitle => 'Em que se deve focar o feed?';

  @override
  String get onbRegionsSub =>
      'Verá sempre o ciclismo global. Escolha que regiões recebem peso extra.';

  @override
  String get onbDisciplinesTitle => 'Que bicicletas o atraem?';

  @override
  String get onbDisciplinesSub =>
      'Marque tudo o que se aplique — usamos isto para etiqueta de cor e priorização.';

  @override
  String get onbDensityTitle => 'Quão denso deve ser o feed?';

  @override
  String get onbDensitySub =>
      'Pode alterar isto a qualquer momento a partir do feed.';

  @override
  String get onbCompactSub =>
      'Máximo de artigos. Linhas de lista, sem imagens.';

  @override
  String get onbComfortSub => 'Equilibrado. Imagem + texto.';

  @override
  String get onbLargeSub => 'Cartões editoriais de destaque.';

  @override
  String get nameWorld => 'Mundo';

  @override
  String get nameEu => 'UE';

  @override
  String get namePoland => 'Polónia';

  @override
  String get nameSpain => 'Espanha';

  @override
  String get descWorld => 'Tudo, em todo o lado.';

  @override
  String get descEu => 'Foco no ciclismo europeu.';

  @override
  String get descPoland => 'Corridas e ciclistas da PL.';

  @override
  String get descSpain => 'Corridas e ciclistas da ES.';

  @override
  String get disciplineCxLong => 'Ciclocrosse';

  @override
  String get descRoad => 'Geral, clássicas, sprints.';

  @override
  String get descMtb => 'XC, DH, enduro, freeride.';

  @override
  String get descGravel => 'Longa distância fora do asfalto.';

  @override
  String get descTrack => 'Corridas em pista.';

  @override
  String get descCx => 'Lama, areia, barreiras.';

  @override
  String get descBmx => 'Corrida e freestyle.';
}
