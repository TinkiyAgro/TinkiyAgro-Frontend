class Resena {
  final String id;
  final String userName;
  final String avatarUrl;
  final String timeAgo;
  final double rating;
  final String content;

  Resena({
    required this.id,
    required this.userName,
    required this.avatarUrl,
    required this.timeAgo,
    required this.rating,
    required this.content,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id']?.toString() ?? '',
      // API uses authorUsername
      userName: json['authorUsername'] ?? json['userName'] ?? json['username'] ?? 'Anónimo',
      avatarUrl: json['avatarUrl'] ?? '',
      timeAgo: json['timeAgo'] ?? json['createdAt'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      // API uses comment
      content: json['comment'] ?? json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'content': content,
  };
}

// Global list of mock reviews initialized to match the user's mockup.
final List<Resena> mockResenas = [
  Resena(
    id: '1',
    userName: 'Haylie Aminoff',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
    timeAgo: 'Hace 32 minutos',
    rating: 4.5,
    content: 'Lorem ipsum dolor sit amet, consetetur sadispscing elitr, sed diam nonumy',
  ),
  Resena(
    id: '2',
    userName: 'Carla Septimus',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
    timeAgo: 'Hace 32 minutos',
    rating: 4.5,
    content: 'Lorem ipsum dolor sit amet, consetetur sadispscing elitr, sed diam nonumy',
  ),
  Resena(
    id: '3',
    userName: 'Carla George',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
    timeAgo: 'Hace 32 minutos',
    rating: 4.5,
    content: 'Lorem ipsum dolor sit amet, consetetur sadispscing elitr, sed diam nonumy',
  ),
  Resena(
    id: '4',
    userName: 'Maren Kenter',
    avatarUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?q=80&w=200&auto=format&fit=crop',
    timeAgo: 'Hace 32 minutos',
    rating: 4.5,
    content: 'Lorem ipsum dolor sit amet, consetetur sadispscing elitr, sed diam nonumy',
  ),
];
