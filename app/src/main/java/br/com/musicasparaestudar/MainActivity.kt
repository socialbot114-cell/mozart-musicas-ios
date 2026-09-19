package br.com.musicaspara.estudar

import android.os.Bundle
import android.os.SystemClock
import android.app.Application
import android.content.ComponentName
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Book
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.MusicNote
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.AndroidViewModel
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.MoreExecutors
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.Locale

private val Night = Color(0xFF152238)
private val Ivory = Color(0xFFF7F3EA)
private val Lavender = Color(0xFFB5A8D8)
private val Sage = Color(0xFF4F6B5D)
private val Gold = Color(0xFFD6A54A)
private val Ink = Color(0xFF222A35)

data class Track(
    val composer: String,
    val title: String,
    val category: String,
    val note: String,
    val audioResource: String? = null
)

data class ComposerProfile(
    val name: String,
    val dates: String,
    val country: String,
    val period: String,
    val bio: String,
    val works: List<String>,
    val portrait: Int
)

class FocusSessionViewModel(private val state: SavedStateHandle) : ViewModel() {
    var isRunning by mutableStateOf(false)
        private set
    var remainingSeconds by mutableIntStateOf(state["remaining"] ?: 25 * 60)
        private set
    var selectedDuration by mutableIntStateOf(state["duration"] ?: 25)
        private set

    private var deadline = 0L

    fun start() {
        if (isRunning || remainingSeconds <= 0) return
        isRunning = true
        deadline = SystemClock.elapsedRealtime() + remainingSeconds * 1_000L
        viewModelScope.launch {
            while (isActive && isRunning) {
                remainingSeconds = ((deadline - SystemClock.elapsedRealtime()).coerceAtLeast(0L) / 1_000L).toInt()
                state["remaining"] = remainingSeconds
                if (remainingSeconds == 0) {
                    isRunning = false
                    break
                }
                delay(500)
            }
        }
    }

    fun pause() {
        if (!isRunning) return
        remainingSeconds = ((deadline - SystemClock.elapsedRealtime()).coerceAtLeast(0L) / 1_000L).toInt()
        isRunning = false
        state["remaining"] = remainingSeconds
    }

    fun setDuration(minutes: Int) {
        if (isRunning) return
        selectedDuration = minutes
        remainingSeconds = minutes * 60
        state["duration"] = minutes
        state["remaining"] = remainingSeconds
    }
}

private val catalog = listOf(
    Track("J. S. Bach", "Goldberg Variations", "Barroco", "Clareza e equilíbrio para longos blocos.", "j_s_bach_goldberg_variations"),
    Track("Wolfgang A. Mozart", "Sonata para Piano n.º 16", "Clássica", "Leveza para leitura e revisão."),
    Track("Ludwig van Beethoven", "Moonlight Sonata", "Piano", "Concentração com presença serena."),
    Track("Frédéric Chopin", "Nocturne Op. 9 No. 2", "Piano", "Piano delicado para acompanhar seu ritmo.", "frederic_chopin_noturno"),
    Track("Claude Debussy", "Clair de Lune", "Clássica", "Uma pausa luminosa entre os capítulos."),
    Track("Erik Satie", "Gymnopédie No. 1", "Piano", "Minimalismo calmo para desacelerar."),
    Track("Maurice Ravel", "Pavane pour une infante défunte", "Clássica", "Texturas suaves para leitura."),
    Track("Ernesto Nazareth", "Odeon", "Brasileira", "Piano brasileiro com leveza."),
    Track("Chiquinha Gonzaga", "Ó Abre Alas", "Brasileira", "Acervo brasileiro para curadoria futura."),
    Track("Antonio Vivaldi", "As Quatro Estações: Primavera", "Barroco", "Energia organizada para exercícios.", "antonio_vivaldi_as_quatro_estacoes_primavera"),
    Track("J. S. Bach", "Prelúdio do Cravo Bem Temperado", "Barroco", "Clareza para começar um bloco.", "j_s_bach_preludio_do_cravo_bem_temperado"),
    Track("J. S. Bach", "Suíte para Violoncelo", "Barroco", "Linhas profundas para concentração.", "j_s_bach_suite_para_violoncelo"),
    Track("J. S. Bach", "Ária na corda Sol", "Barroco", "Uma pausa musical serena.", "j_s_bach_aria_na_corda_sol"),
    Track("J. S. Bach", "Partita para Violino", "Barroco", "Música para foco prolongado.", "j_s_bach_partita_para_violino"),
    Track("J. S. Bach", "Suíte Inglesa", "Barroco", "Estrutura e ritmo para estudar.", "j_s_bach_suite_inglesa"),
    Track("J. S. Bach", "Invenção a duas vozes", "Barroco", "Movimento leve para exercícios.", "j_s_bach_invencao_a_duas_vozes"),
    Track("J. S. Bach", "Tocata para Órgão", "Barroco", "Som amplo para foco profundo.", "j_s_bach_tocata_para_orgao"),
    Track("Frédéric Chopin", "Estudo", "Piano", "Piano para resolver desafios.", "frederic_chopin_estudo"),
    Track("Frédéric Chopin", "Valsa", "Piano", "Movimento suave para leitura.", "frederic_chopin_valsa"),
    Track("Frédéric Chopin", "Mazurca", "Piano", "Ritmo delicado para acompanhar ideias.", "frederic_chopin_mazurca"),
    Track("Franz Schubert", "Impromptu", "Piano", "Piano expressivo sem distrações.", "franz_schubert_impromptu"),
    Track("Franz Schubert", "Sonata para Piano", "Piano", "Uma sessão longa de concentração.", "franz_schubert_sonata_para_piano"),
    Track("Johannes Brahms", "Intermezzo", "Piano", "Calma e profundidade.", "johannes_brahms_intermezzo"),
    Track("Gabriel Fauré", "Pavana", "Clássica", "Texturas suaves para leitura.", "gabriel_faure_pavana")
)

private val composers = listOf(
    ComposerProfile("Johann Sebastian Bach", "1685–1750", "Alemanha", "Barroco", "Bach uniu contraponto, dança e tradição litúrgica em uma obra de precisão extraordinária.", listOf("Variações Goldberg", "O Cravo Bem Temperado", "Suítes para Violoncelo"), R.drawable.artist_bach),
    ComposerProfile("Wolfgang Amadeus Mozart", "1756–1791", "Áustria", "Classicismo", "Mozart combinou clareza formal, invenção melódica e grande variedade dramática.", listOf("Uma Pequena Serenata", "A Flauta Mágica", "Requiem"), R.drawable.artist_mozart),
    ComposerProfile("Ludwig van Beethoven", "1770–1827", "Alemanha", "Classicismo e Romantismo", "Beethoven ampliou a força expressiva da música clássica e transformou a sonata e a sinfonia.", listOf("Sinfonia nº 5", "Sinfonia nº 9", "Sonata ao Luar"), R.drawable.artist_beethoven),
    ComposerProfile("Frédéric Chopin", "1810–1849", "Polônia / França", "Romantismo", "Chopin concentrou sua criação no piano, explorando novas cores, formas e possibilidades técnicas.", listOf("Noturnos", "Estudos", "Prelúdios Op. 28"), R.drawable.artist_chopin),
    ComposerProfile("Claude Debussy", "1862–1918", "França", "Modernismo francês", "Debussy renovou a harmonia e o timbre, criando música de contornos fluidos e atmosferas singulares.", listOf("Clair de Lune", "La Mer", "Estampes"), R.drawable.artist_debussy),
    ComposerProfile("Erik Satie", "1866–1925", "França", "Vanguarda francesa", "Satie criou peças concisas e irônicas cuja simplicidade influenciou a música do século XX.", listOf("Gymnopédies", "Gnossiennes", "Socrate"), R.drawable.artist_satie),
    ComposerProfile("Maurice Ravel", "1875–1937", "França", "Modernismo francês", "Ravel foi um mestre da precisão e das cores instrumentais, unindo formas clássicas e linguagem moderna.", listOf("Boléro", "Daphnis et Chloé", "Pavana"), R.drawable.artist_ravel),
    ComposerProfile("Franz Schubert", "1797–1828", "Áustria", "Romantismo", "Schubert combinou formas clássicas com uma expressão lírica profundamente pessoal.", listOf("Impromptus", "Winterreise", "Sinfonia Inacabada"), R.drawable.artist_schubert),
    ComposerProfile("Johannes Brahms", "1833–1897", "Alemanha", "Romantismo", "Brahms conciliou formas herdadas de Bach e Beethoven com uma linguagem densa e expressiva.", listOf("Intermezzi Op. 118", "Sinfonia nº 1", "Danças Húngaras"), R.drawable.artist_brahms),
    ComposerProfile("Franz Liszt", "1811–1886", "Hungria", "Romantismo", "Liszt expandiu os recursos técnicos do piano e ajudou a consolidar o poema sinfônico.", listOf("Liebesträume", "Rapsódias Húngaras", "Sonata em Si menor"), R.drawable.artist_liszt),
    ComposerProfile("Gabriel Fauré", "1845–1924", "França", "Romantismo tardio", "Fauré desenvolveu uma linguagem harmônica elegante em canções, piano e música de câmara.", listOf("Requiem", "Pavana", "Sicilienne"), R.drawable.artist_faure),
    ComposerProfile("Robert Schumann", "1810–1856", "Alemanha", "Romantismo", "Schumann uniu música e literatura em peças marcadas por contrastes de humor e imaginação poética.", listOf("Cenas Infantis", "Carnaval", "Dichterliebe"), R.drawable.artist_schumann),
    ComposerProfile("Antonio Vivaldi", "1678–1741", "Itália", "Barroco", "Vivaldi ajudou a definir o concerto barroco com energia rítmica e efeitos instrumentais vívidos.", listOf("As Quatro Estações", "Gloria", "L'estro armonico"), R.drawable.artist_vivaldi),
    ComposerProfile("Sergei Rachmaninoff", "1873–1943", "Rússia / Estados Unidos", "Romantismo tardio", "Rachmaninoff foi compositor, pianista e regente, célebre por melodias amplas e escrita exigente.", listOf("Concerto para Piano nº 2", "Rapsódia de Paganini", "Prelúdio em dó sustenido menor"), R.drawable.artist_rachmaninoff)
)

class AudioPlayerViewModel(application: Application) : AndroidViewModel(application) {
    private var player: MediaController? = null
    var isPlaying by mutableStateOf(false)
        private set
    var currentResource by mutableStateOf<String?>(null)
        private set

    init {
        val token = SessionToken(application, ComponentName(application, PlaybackService::class.java))
        val future = MediaController.Builder(application, token).buildAsync()
        future.addListener({
            if (!future.isCancelled) {
                player = future.get()
                player?.addListener(object : Player.Listener {
                    override fun onIsPlayingChanged(isPlayingNow: Boolean) { isPlaying = isPlayingNow }
                    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) { currentResource = mediaItem?.mediaId }
                })
            }
        }, MoreExecutors.directExecutor())
    }

    fun toggle(track: Track) {
        val resource = track.audioResource ?: return
        val controller = player ?: return
        if (currentResource != resource) {
            val id = resourceId(resource)
            controller.setMediaItem(MediaItem.Builder().setMediaId(resource).setUri("android.resource://${getApplication<Application>().packageName}/$id").build())
            currentResource = resource
            controller.prepare()
        }
        if (controller.isPlaying) controller.pause() else controller.play()
    }

    fun stop() { player?.stop(); currentResource = null; isPlaying = false }

    override fun onCleared() { player?.release() }

    private fun resourceId(name: String): Int = when (name) {
        "antonio_vivaldi_as_quatro_estacoes_primavera" -> R.raw.antonio_vivaldi_as_quatro_estacoes_primavera
        "franz_schubert_impromptu" -> R.raw.franz_schubert_impromptu
        "franz_schubert_sonata_para_piano" -> R.raw.franz_schubert_sonata_para_piano
        "frederic_chopin_estudo" -> R.raw.frederic_chopin_estudo
        "frederic_chopin_mazurca" -> R.raw.frederic_chopin_mazurca
        "frederic_chopin_noturno" -> R.raw.frederic_chopin_noturno
        "frederic_chopin_valsa" -> R.raw.frederic_chopin_valsa
        "gabriel_faure_pavana" -> R.raw.gabriel_faure_pavana
        "j_s_bach_aria_na_corda_sol" -> R.raw.j_s_bach_aria_na_corda_sol
        "j_s_bach_goldberg_variations" -> R.raw.j_s_bach_goldberg_variations
        "j_s_bach_invencao_a_duas_vozes" -> R.raw.j_s_bach_invencao_a_duas_vozes
        "j_s_bach_partita_para_violino" -> R.raw.j_s_bach_partita_para_violino
        "j_s_bach_preludio_do_cravo_bem_temperado" -> R.raw.j_s_bach_preludio_do_cravo_bem_temperado
        "j_s_bach_suite_inglesa" -> R.raw.j_s_bach_suite_inglesa
        "j_s_bach_suite_para_violoncelo" -> R.raw.j_s_bach_suite_para_violoncelo
        "j_s_bach_tocata_para_orgao" -> R.raw.j_s_bach_tocata_para_orgao
        "johannes_brahms_intermezzo" -> R.raw.johannes_brahms_intermezzo
        else -> error("Recurso de áudio não cadastrado: $name")
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { StudyMusicApp() }
    }
}

class StudyStatsViewModel(application: Application) : AndroidViewModel(application) {
    private val preferences = application.getSharedPreferences("study_stats", Application.MODE_PRIVATE)
    var minutesStudied by mutableIntStateOf(preferences.getInt("minutes", 0))
        private set
    var tracksStarted by mutableIntStateOf(preferences.getInt("tracks", 0))
        private set

    fun trackStarted() {
        tracksStarted++
        persist()
    }

    fun minuteStudied() {
        minutesStudied++
        persist()
    }

    private fun persist() {
        preferences.edit().putInt("minutes", minutesStudied).putInt("tracks", tracksStarted).apply()
    }
}

@Composable
private fun StudyMusicApp() {
    var screen by remember { mutableIntStateOf(0) }
    var selectedTrack by remember { mutableStateOf(catalog[3]) }
    val focusSession: FocusSessionViewModel = viewModel()
    val audioPlayer: AudioPlayerViewModel = viewModel()
    val studyStats: StudyStatsViewModel = viewModel()
    MaterialTheme {
        Scaffold(
            containerColor = Ivory,
            bottomBar = {
                Column {
                    MiniPlayer(audioPlayer, selectedTrack, studyStats, onOpen = { screen = 3 })
                    AppNavigation(screen, onSelect = { screen = it })
                }
            }
        ) { padding ->
            when (screen) {
                0 -> HomeScreen(Modifier.padding(padding), selectedTrack, onTrackSelect = { selectedTrack = it; screen = 3 }, onOpenFocus = { screen = 3 })
                1 -> ExploreScreen(Modifier.padding(padding), onTrackSelect = { selectedTrack = it; screen = 3 })
                2 -> UniverseScreen(Modifier.padding(padding), onTrackSelect = { selectedTrack = it; screen = 3 })
                3 -> FocusScreen(Modifier.padding(padding), selectedTrack, focusSession, audioPlayer)
                4 -> LibraryScreen(Modifier.padding(padding), onTrackSelect = { selectedTrack = it; screen = 3 })
                else -> ProfileScreen(Modifier.padding(padding), studyStats)
            }
        }
    }
}

@Composable
private fun MiniPlayer(audioPlayer: AudioPlayerViewModel, track: Track, stats: StudyStatsViewModel, onOpen: () -> Unit) {
    LaunchedEffect(audioPlayer.currentResource) {
        if (audioPlayer.currentResource != null) stats.trackStarted()
    }
    LaunchedEffect(audioPlayer.isPlaying, audioPlayer.currentResource) {
        while (audioPlayer.isPlaying) {
            delay(60_000)
            if (audioPlayer.isPlaying) stats.minuteStudied()
        }
    }
    if (audioPlayer.currentResource != null) {
        val playingTrack = catalog.firstOrNull { it.audioResource == audioPlayer.currentResource } ?: track
        Surface(color = Night, modifier = Modifier.fillMaxWidth().height(72.dp).clickable(onClick = onOpen)) {
            Row(Modifier.padding(horizontal = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                Image(painterResource(coverResource(playingTrack.category)), "Capa de ${playingTrack.category}", Modifier.size(48.dp).clip(RoundedCornerShape(10.dp)), contentScale = ContentScale.Crop)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(playingTrack.title, color = Color.White, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(playingTrack.composer, color = Lavender, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                IconButton(onClick = { audioPlayer.toggle(playingTrack) }) {
                    Icon(if (audioPlayer.isPlaying) Icons.Outlined.Pause else Icons.Outlined.PlayArrow, "Pausar ou continuar", tint = Color.White)
                }
                IconButton(onClick = audioPlayer::stop) { Icon(Icons.Outlined.Close, "Parar música", tint = Color.White) }
            }
        }
    }
}

@Composable
private fun ProfileScreen(modifier: Modifier, stats: StudyStatsViewModel) {
    LazyColumn(modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        item {
            Text("Seu perfil", fontSize = 30.sp, fontWeight = FontWeight.Bold, color = Night)
            Text("Acompanhe seu ritmo de concentração.", color = Ink.copy(alpha = .72f), fontSize = 16.sp)
        }
        item {
            Card(colors = CardDefaults.cardColors(containerColor = Night), shape = RoundedCornerShape(24.dp)) {
                Column(Modifier.padding(24.dp)) {
                    Text("SEU FOCO", color = Lavender, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                    Spacer(Modifier.height(8.dp))
                    Text("Cada minuto conta.", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                    Text("Continue criando um espaço para estudar.", color = Color.White.copy(alpha = .75f), fontSize = 15.sp)
                }
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatCard("${stats.minutesStudied}", "minutos estudados", Modifier.weight(1f))
                StatCard("${stats.tracksStarted}", "músicas ouvidas", Modifier.weight(1f))
            }
        }
        item { SectionTitle("Como seus dados funcionam") }
        item {
            Text("Os minutos são contabilizados somente enquanto uma música está reproduzindo. As estatísticas ficam salvas neste aparelho e não exigem conta.", color = Ink.copy(alpha = .78f), fontSize = 16.sp, lineHeight = 23.sp)
        }
        item { SectionTitle("Seu próximo passo") }
        item { Text("Escolha uma faixa, inicie uma sessão de foco e deixe a música acompanhar seu ritmo.", color = Ink.copy(alpha = .78f), fontSize = 16.sp, lineHeight = 23.sp) }
    }
}

@Composable
private fun StatCard(value: String, label: String, modifier: Modifier) {
    Card(modifier, colors = CardDefaults.cardColors(containerColor = Color.White), shape = RoundedCornerShape(20.dp)) {
        Column(Modifier.padding(18.dp)) {
            Text(value, color = Night, fontSize = 28.sp, fontWeight = FontWeight.Bold)
            Text(label, color = Ink.copy(alpha = .72f), fontSize = 14.sp)
        }
    }
}

@Composable
private fun AppNavigation(selected: Int, onSelect: (Int) -> Unit) {
    val items = listOf("Início", "Explorar", "Universo", "Foco", "Biblioteca", "Perfil")
    val icons = listOf(Icons.Outlined.Home, Icons.Outlined.Explore, Icons.Outlined.Book, Icons.Outlined.Timer, Icons.Outlined.Book, Icons.Outlined.Person)
    NavigationBar(containerColor = Color.White) {
        items.forEachIndexed { index, label ->
            NavigationBarItem(selected = selected == index, onClick = { onSelect(index) }, icon = {
                Icon(icons[index], contentDescription = null)
            }, label = { Text(label, fontSize = 14.sp) })
        }
    }
}

@Composable
private fun HomeScreen(modifier: Modifier, selectedTrack: Track, onTrackSelect: (Track) -> Unit, onOpenFocus: () -> Unit) {
    LazyColumn(modifier = modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        item {
            Text("Bom estudo", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Night)
            Text("Pequenos momentos, grandes conquistas.", color = Ink.copy(alpha = .7f))
        }
        item {
            Card(colors = CardDefaults.cardColors(containerColor = Night), shape = RoundedCornerShape(24.dp)) {
                Column(Modifier.padding(24.dp)) {
            Text("FOCO PROFUNDO", color = Lavender, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(32.dp))
                    Text("Piano suave para entrar no ritmo", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(16.dp))
                    Button(onClick = onOpenFocus, colors = ButtonDefaults.buttonColors(containerColor = Gold, contentColor = Night)) {
                        Icon(Icons.Outlined.PlayArrow, null)
                        Spacer(Modifier.width(8.dp))
                        Text("Começar agora")
                    }
                }
            }
        }
        item { SectionTitle("Escolha seu momento") }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                MomentCard("Piano para\nestudar", "Piano", Modifier.weight(1f)) { onTrackSelect(catalog.first { it.category == "Piano" }) }
                MomentCard("Barroco para\nconcentração", "Barroco", Modifier.weight(1f)) { onTrackSelect(catalog.first { it.category == "Barroco" }) }
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                MomentCard("Clássica para\nleitura", "Leitura", Modifier.weight(1f)) { onTrackSelect(catalog.first { it.category == "Clássica" }) }
                MomentCard("Brasil\ninstrumental", "Brasil", Modifier.weight(1f)) { onTrackSelect(catalog.first { it.category == "Brasileira" }) }
            }
        }
        item { SectionTitle("Continue ouvindo") }
        item { MiniTrack(selectedTrack, onClick = onOpenFocus) }
    }
}

@Composable
private fun UniverseScreen(modifier: Modifier, onTrackSelect: (Track) -> Unit) {
    var selected by remember { mutableStateOf<ComposerProfile?>(null) }
    val profile = selected
    if (profile != null) {
        LazyColumn(modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            item {
                IconButton(onClick = { selected = null }) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Voltar") }
                Image(painterResource(profile.portrait), "Ilustração inspirada em ${profile.name}", Modifier.fillMaxWidth().height(230.dp).clip(RoundedCornerShape(28.dp)), contentScale = ContentScale.Crop)
            }
            item {
                Text(profile.name, fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Night)
                Text("${profile.dates} · ${profile.country}", color = Ink.copy(alpha = .72f), fontSize = 16.sp)
                Surface(shape = CircleShape, color = Lavender, modifier = Modifier.padding(top = 10.dp)) { Text(profile.period, Modifier.padding(horizontal = 14.dp, vertical = 8.dp), color = Night, fontSize = 14.sp) }
            }
            item { Text(profile.bio, color = Ink, fontSize = 16.sp, lineHeight = 24.sp) }
            item { SectionTitle("Obras para conhecer") }
            items(profile.works) { work -> Text("•  $work", color = Night, fontSize = 16.sp, modifier = Modifier.padding(vertical = 4.dp)) }
            item { SectionTitle("Faixas disponíveis") }
            items(catalog.filter { it.composer.contains(profile.name.substringAfterLast(" "), ignoreCase = true) }) { track -> TrackRow(track) { onTrackSelect(track) } }
        }
    } else {
        LazyColumn(modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            item {
                Text("Universo Musical", fontSize = 30.sp, fontWeight = FontWeight.Bold, color = Night)
                Text("Conheça as histórias por trás das obras.", color = Ink.copy(alpha = .72f), fontSize = 16.sp)
            }
            item {
                Card(colors = CardDefaults.cardColors(containerColor = Night), shape = RoundedCornerShape(24.dp)) {
                    Column(Modifier.padding(22.dp)) {
                        Text("ESCUTA COM CONTEXTO", color = Lavender, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                        Spacer(Modifier.height(8.dp))
                        Text("Grandes ideias começam por uma história.", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
            items(composers.chunked(2)) { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEach { composer ->
                        ComposerCard(composer, Modifier.weight(1f)) { selected = composer }
                    }
                    if (row.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun ComposerCard(profile: ComposerProfile, modifier: Modifier, onClick: () -> Unit) {
    Card(modifier.clickable(onClick = onClick), colors = CardDefaults.cardColors(containerColor = Color.White), shape = RoundedCornerShape(20.dp)) {
        Column {
            Image(painterResource(profile.portrait), "Ilustração inspirada em ${profile.name}", Modifier.fillMaxWidth().height(150.dp), contentScale = ContentScale.Crop)
            Column(Modifier.padding(14.dp)) {
                Text(profile.name, color = Night, fontWeight = FontWeight.Bold, fontSize = 16.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Text(profile.period, color = Ink.copy(alpha = .7f), fontSize = 14.sp)
                Text("Ver história", color = Gold, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 10.dp))
            }
        }
    }
}

@Composable
private fun MomentCard(title: String, tag: String, modifier: Modifier, onClick: () -> Unit) {
    Card(modifier.clickable(onClick = onClick), colors = CardDefaults.cardColors(containerColor = Color.White), shape = RoundedCornerShape(18.dp)) {
        Column(Modifier.padding(16.dp)) {
            Image(painterResource(coverResource(tag)), "Capa de $tag", Modifier.fillMaxWidth().height(92.dp).clip(RoundedCornerShape(14.dp)), contentScale = ContentScale.Crop)
            Spacer(Modifier.height(14.dp))
            Text(title, color = Night, fontWeight = FontWeight.SemiBold, lineHeight = 18.sp)
            Text(tag, color = Ink.copy(alpha = .65f), fontSize = 14.sp)
        }
    }
}

@Composable
private fun ExploreScreen(modifier: Modifier, onTrackSelect: (Track) -> Unit) {
    var filter by remember { mutableStateOf("Foco") }
    val filtered = catalog.filter { filter == "Foco" || (filter == "Leitura" && it.category == "Clássica") || (filter == "Sono" && it.category == "Piano") || (filter == "ENEM" && it.category != "Brasileira") }
    LazyColumn(modifier = modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        item {
            Text("Estude do seu jeito", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Night)
            Text("Música certa para cada momento da sua jornada.", color = Ink.copy(alpha = .7f))
        }
        item { FilterRow(filter, onFilter = { filter = it }) }
        items(filtered.take(6)) { track -> PlaylistCard(track.title, "${track.composer} · ${track.note}", track.category, onClick = { onTrackSelect(track) }) }
        item { SectionTitle("Compositores em destaque") }
        item { Text("Bach · Chopin · Debussy · Satie", color = Ink.copy(alpha = .75f), fontSize = 16.sp) }
    }
}

@Composable
private fun FilterRow(selected: String, onFilter: (String) -> Unit) {
    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        listOf("Foco", "Leitura", "Sono", "ENEM").forEach { label ->
            Surface(shape = CircleShape, color = if (label == selected) Lavender else Color.White, modifier = Modifier.clickable { onFilter(label) }) {
                Text(label, Modifier.padding(horizontal = 16.dp, vertical = 10.dp), color = Night, fontSize = 14.sp)
            }
        }
    }
}

@Composable
private fun PlaylistCard(title: String, subtitle: String, category: String, onClick: () -> Unit) {
    Card(Modifier.fillMaxWidth().clickable(onClick = onClick), colors = CardDefaults.cardColors(containerColor = Color.White), shape = RoundedCornerShape(20.dp)) {
        Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(82.dp).clip(RoundedCornerShape(14.dp)), contentAlignment = Alignment.Center) {
                Image(painterResource(coverResource(category)), "Capa de $category", Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
            }
            Spacer(Modifier.width(16.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.Bold, color = Night)
                Text(subtitle, color = Ink.copy(alpha = .68f), fontSize = 14.sp)
            }
            Icon(Icons.Outlined.PlayArrow, null, tint = Gold)
        }
    }
}

@Composable
private fun FocusScreen(modifier: Modifier, track: Track, session: FocusSessionViewModel, audioPlayer: AudioPlayerViewModel) {
    val isRunning = session.isRunning
    val seconds = session.remainingSeconds
    val minutes = seconds / 60
    val remainingSeconds = seconds % 60
    LazyColumn(modifier = modifier.fillMaxSize().padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
        item {
            Text("Sessão de foco", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Night)
            Text("Sem anúncios durante seu foco.", color = Ink.copy(alpha = .7f))
        }
        item {
            Box(Modifier.size(210.dp).clip(RoundedCornerShape(28.dp)).background(Night), contentAlignment = Alignment.Center) {
                Image(painterResource(coverResource(track.category)), "Capa de ${track.category}", Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
            }
        }
        item {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(track.title, color = Night, fontSize = 20.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(track.composer, color = Ink.copy(alpha = .7f))
                Text(if (track.audioResource == null) "Áudio ainda não disponível para esta obra." else "Áudio local incluído no catálogo.", color = Sage, fontSize = 14.sp, modifier = Modifier.padding(top = 8.dp))
                if (track.audioResource != null) {
                    Text("Fonte: Wikimedia Commons · referência em catalogo.json", color = Ink.copy(alpha = .65f), fontSize = 14.sp)
                }
            }
        }
        item {
            Surface(shape = CircleShape, color = Color.White, tonalElevation = 2.dp) {
                Text(String.format(Locale.ROOT, "%02d:%02d", minutes, remainingSeconds), Modifier.padding(28.dp), fontSize = 38.sp, color = Night, fontWeight = FontWeight.Bold)
            }
        }
        item {
            Button(onClick = {
                if (track.audioResource != null) audioPlayer.toggle(track)
                if (isRunning) session.pause() else session.start()
            }, colors = ButtonDefaults.buttonColors(containerColor = Night), modifier = Modifier.fillMaxWidth().height(52.dp)) {
                Icon(if (audioPlayer.isPlaying) Icons.Outlined.Pause else Icons.Outlined.PlayArrow, null)
                Spacer(Modifier.width(8.dp))
                Text(if (isRunning) "Pausar sessão" else "Iniciar sessão")
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(25, 50, 90).forEach { duration ->
                    Surface(shape = CircleShape, color = if (session.selectedDuration == duration) Lavender else Color.White, modifier = Modifier.size(width = 88.dp, height = 48.dp).clickable { session.setDuration(duration) }) {
                        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) { Text("$duration min", color = Night, fontSize = 14.sp) }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LibraryScreen(modifier: Modifier, onTrackSelect: (Track) -> Unit) {
    var query by remember { mutableStateOf("") }
    var filter by remember { mutableStateOf("Todos") }
    val tracks = catalog.filter { it.composer.contains(query, true) || it.title.contains(query, true) }
    Column(modifier = modifier.fillMaxSize().padding(20.dp)) {
        Text("Biblioteca de compositores", fontSize = 26.sp, fontWeight = FontWeight.Bold, color = Night)
        Text("Obras que inspiram mentes curiosas.", color = Ink.copy(alpha = .7f))
        Spacer(Modifier.height(16.dp))
        OutlinedTextField(value = query, onValueChange = { query = it }, leadingIcon = { Icon(Icons.Outlined.Search, null) }, placeholder = { Text("Buscar compositor ou obra") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp))
        Spacer(Modifier.height(12.dp))
        LibraryFilterRow(filter, onFilter = { filter = it })
        Spacer(Modifier.height(12.dp))
            Text("Catálogo inicial", color = Ink.copy(alpha = .65f), fontSize = 14.sp)
        LazyColumn(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            items(tracks.filter { filter == "Todos" || it.category == filter }) { track ->
                TrackRow(track, onClick = { onTrackSelect(track) })
            }
        }
    }
}

@Composable
private fun LibraryFilterRow(selected: String, onFilter: (String) -> Unit) {
    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        listOf("Todos", "Clássica", "Brasileira", "Piano", "Barroco").forEach { label ->
            Surface(shape = CircleShape, color = if (label == selected) Lavender else Color.White, modifier = Modifier.clickable { onFilter(label) }) {
                Text(label, Modifier.padding(horizontal = 12.dp, vertical = 10.dp), color = Night, fontSize = 14.sp)
            }
        }
    }
}

@Composable
private fun TrackRow(track: Track, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(64.dp).clip(RoundedCornerShape(12.dp)), contentAlignment = Alignment.Center) {
                Image(painterResource(coverResource(track.category)), "Capa de ${track.category}", Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(track.composer, fontWeight = FontWeight.Bold, color = Night)
            Text(track.title, color = Ink.copy(alpha = .72f), maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text("Composição em domínio público; licença da gravação em verificação", color = Sage, fontSize = 14.sp)
        }
        Icon(Icons.Outlined.PlayArrow, null, tint = Gold)
    }
    HorizontalDivider(color = Ink.copy(alpha = .08f))
}

@Composable
private fun MiniTrack(track: Track, onClick: () -> Unit) {
    Card(Modifier.fillMaxWidth().clickable(onClick = onClick), colors = CardDefaults.cardColors(containerColor = Color.White), shape = RoundedCornerShape(18.dp)) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Image(painterResource(coverResource(track.category)), "Capa de ${track.category}", Modifier.size(56.dp).clip(RoundedCornerShape(12.dp)), contentScale = ContentScale.Crop)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(track.title, color = Night, fontWeight = FontWeight.Bold)
                Text(track.composer, color = Ink.copy(alpha = .65f), fontSize = 13.sp)
            }
            Icon(Icons.Outlined.PlayArrow, null, tint = Gold)
        }
    }
}

@Composable
private fun SectionTitle(text: String) = Text(text, fontSize = 20.sp, color = Night, fontWeight = FontWeight.Bold)

private fun coverResource(category: String): Int = when {
    category.contains("Brasil", ignoreCase = true) -> R.drawable.cover_brasil
    category.contains("Piano", ignoreCase = true) -> R.drawable.cover_piano
    category.contains("Barroco", ignoreCase = true) -> R.drawable.cover_barroco
    category.contains("Leitura", ignoreCase = true) || category.contains("Clássica", ignoreCase = true) -> R.drawable.cover_leitura
    else -> R.drawable.cover_foco
}
