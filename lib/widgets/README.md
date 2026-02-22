# Widgets Reutilizáveis

Este diretório contém widgets reutilizáveis para manter consistência de design em todo o aplicativo.

## AppBarWidget

Widget reutilizável para AppBar padrão do aplicativo. Garante consistência visual em todas as telas.

### Uso Básico

```dart
import 'package:inspecao/widgets/app_bar_widget.dart';

Scaffold(
  appBar: const AppBarWidget(
    title: 'Título da Tela',
  ),
  body: // seu conteúdo
)
```

### Uso com Ações

```dart
Scaffold(
  appBar: AppBarWidget(
    title: 'Calendário',
    actions: [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          // ação
        },
      ),
    ],
  ),
  body: // seu conteúdo
)
```

### Parâmetros Disponíveis

- `title` (obrigatório): Título da tela
- `actions`: Lista de widgets de ação (botões, etc.)
- `leading`: Widget personalizado para o botão de voltar
- `automaticallyImplyLeading`: Se deve mostrar botão de voltar automaticamente (padrão: true)
- `backgroundColor`: Cor de fundo (padrão: Color(0xFF1976D2))
- `foregroundColor`: Cor do texto e ícones (padrão: Colors.white)
- `elevation`: Elevação da AppBar (padrão: 0)
- `bottom`: Widget para exibir abaixo do título (ex: TabBar)
- `centerTitle`: Se o título deve ser centralizado (padrão: false)

## BottomNavBarWidget

Widget reutilizável para BottomNavigationBar padrão do aplicativo.

### Uso Básico

```dart
import 'package:inspecao/widgets/bottom_nav_bar_widget.dart';

Scaffold(
  body: // seu conteúdo
  bottomNavigationBar: BottomNavBarWidget(
    currentIndex: _selectedIndex,
    onTap: (index) {
      setState(() => _selectedIndex = index);
    },
    items: [
      BottomNavItem(
        label: 'Inspeções',
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
        screen: 'inspections',
      ),
      BottomNavItem(
        label: 'Calendário',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        screen: 'calendar',
      ),
    ],
  ),
)
```

### Parâmetros Disponíveis

- `currentIndex` (obrigatório): Índice do item selecionado
- `onTap` (obrigatório): Callback quando um item é tocado
- `items` (obrigatório): Lista de itens do menu
- `selectedColor`: Cor do item selecionado (padrão: Color(0xFF1976D2))
- `unselectedColor`: Cor dos itens não selecionados
- `backgroundColor`: Cor de fundo do menu

## Quando Usar

### Use AppBarWidget quando:
- A tela precisa de um AppBar simples e padrão
- Você quer manter consistência visual
- Não precisa de customizações complexas

### Use AppBar customizado quando:
- A tela precisa de um header completamente diferente (ex: gradient, layout especial)
- Precisa de funcionalidades específicas que não cabem no widget padrão
- Exemplo: `InspectionsScreen` com `_buildGoAuditsHeader()` customizado

### Use BottomNavBarWidget quando:
- A tela faz parte da navegação principal do app
- Precisa de menu inferior consistente
- Exemplo: `HomeScreen` com navegação entre telas principais

## Benefícios

1. **Consistência**: Todas as telas que usam os widgets terão o mesmo visual
2. **Manutenção**: Mudanças no design podem ser feitas em um único lugar
3. **Produtividade**: Menos código duplicado
4. **Flexibilidade**: Widgets permitem customizações quando necessário

## Exemplos de Uso

### Tela Simples com AppBar
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Minha Tela',
      ),
      body: Center(
        child: Text('Conteúdo da tela'),
      ),
    );
  }
}
```

### Tela com Navegação Inferior
```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavItem(
            label: 'Início',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            screen: 'home',
          ),
          BottomNavItem(
            label: 'Inspeções',
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            screen: 'inspections',
          ),
        ],
      ),
    );
  }
}
```
