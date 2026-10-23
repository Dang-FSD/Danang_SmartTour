class HeritageGuide {
  final int attractionId;
  final String historicalEra;
  final String storyVi;
  final String storyEn;
  final List<EtiquetteRule> etiquetteRules;
  final String sdgContribution;
  final List<String> highlights;

  const HeritageGuide({
    required this.attractionId,
    required this.historicalEra,
    required this.storyVi,
    required this.storyEn,
    required this.etiquetteRules,
    required this.sdgContribution,
    required this.highlights,
  });

  static HeritageGuide getGuideForAttraction(int attractionId) {
    return _heritageDatabase[attractionId] ?? _defaultGuide(attractionId);
  }

  static HeritageGuide _defaultGuide(int id) {
    return HeritageGuide(
      attractionId: id,
      historicalEra: 'Da Nang Cultural & Historical Heritage',
      storyVi: 'Điểm đến tiêu biểu phản ánh nét đẹp thiên nhiên, con người và chiều sâu văn hiến của thành phố đáng sống Đà Nẵng bên bờ Biển Đông.',
      storyEn: 'A landmark reflecting the natural beauty, people, and deep cultural heritage of Da Nang on the East Sea coast.',
      etiquetteRules: const [
        EtiquetteRule(
          icon: '👕',
          titleVi: 'Trang phục lịch sự',
          titleEn: 'Modest Clothing',
          descVi: 'Trang phục gọn gàng, tôn trọng không gian công cộng và người dân địa phương.',
          descEn: 'Wear neat clothing, respecting public spaces and local residents.',
          isStrict: false,
        ),
        EtiquetteRule(
          icon: '🚮',
          titleVi: 'Bảo vệ cảnh quan',
          titleEn: 'Keep Clean',
          descVi: 'Không xả rác, giữ gìn vệ sinh môi trường xanh - sạch - đẹp.',
          descEn: 'Do not litter; help keep the natural environment clean and pristine.',
          isStrict: true,
        ),
      ],
      sdgContribution: 'SDG 11: Preserve public spaces & sustainable urban heritage',
      highlights: const ['Scenic Natural Landscapes', 'Quang Nam - Da Nang Cultural Identity'],
    );
  }

  static final Map<int, HeritageGuide> _heritageDatabase = {
    // 6: Bảo tàng Điêu khắc Chăm
    6: const HeritageGuide(
      attractionId: 6,
      historicalEra: 'Champa Kingdom (4th - 14th Century)',
      storyVi: '''Bảo tàng Điêu khắc Chăm Đà Nẵng được xây dựng từ năm 1915 bởi Viện Viễn Đông Bác Cổ Pháp (EFEO), là bảo tàng lưu giữ bộ sưu tập hiện vật điêu khắc Chăm Pa quy mô và độc bản nhất hành tinh.

Từng bức tượng sa thạch tại đây như Nữ thần Ánh sáng Tara, Đài thờ Mỹ Sơn E1, Đài thờ Trà Kiệu và Tượng thần Shiva múa là những Bảo vật Quốc gia vô giá, thể hiện đỉnh cao nghệ thuật chạm khắc đá kết hợp triết lý Ấn Độ giáo và tâm hồn bản địa của người Chăm cổ.''',
      storyEn: '''Built in 1915 by the École Française d’Extrême-Orient (EFEO), the Museum of Cham Sculpture houses the world's most comprehensive collection of Champa sandstone art.

Masterpieces such as the Bodhisattva Tara, the Tra Kieu Altar, the My Son E1 Altar, and dancing Shiva reliefs are National Treasures, representing the zenith of spiritual sculpture fusing Hindu cosmology with ancient Cham artistic ingenuity.''',
      etiquetteRules: [
        EtiquetteRule(
          icon: '🚫',
          titleVi: 'Không chạm tay vào sa thạch',
          titleEn: 'Do Not Touch Sandstone',
          descVi: 'Sa thạch cổ nghìn năm rất nhạy cảm với mồ hôi muối và axit từ tay người.',
          descEn: 'Ancient sandstone is highly vulnerable to skin oils and moisture.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '📸',
          titleVi: 'Tắt đèn Flash khi chụp ảnh',
          titleEn: 'No Camera Flash',
          descVi: 'Ánh sáng cường độ cao làm biến đổi bề mặt khoáng vật của hiện vật cổ.',
          descEn: 'High-intensity flash deteriorates ancient mineral pigment coatings.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '🤫',
          titleVi: 'Giữ yên lặng tĩnh tâm',
          titleEn: 'Quiet Contemplation',
          descVi: 'Nói khẽ, chuyển điện thoại sang chế độ rung để tôn trọng người xem khác.',
          descEn: 'Speak softly and switch phones to silent mode to respect fellow visitors.',
          isStrict: false,
        ),
      ],
      sdgContribution: 'SDG 11.4: Safeguard irreplaceable world cultural heritage',
      highlights: ['National Treasure Tara Bodhisattva', 'Tra Kieu Altar', 'Dancing Shiva Reliefs'],
    ),

    // 7: Chùa Linh Ứng Bãi Bụt Sơn Trà
    7: const HeritageGuide(
      attractionId: 7,
      historicalEra: 'Mahayana Buddhism & Coastal Beliefs',
      storyVi: '''Tọa lạc trên bán đảo Sơn Trà ở độ cao tựa lưng vào đỉnh núi nguyên sinh, Chùa Linh Ứng Bãi Bụt nổi tiếng với pho tượng Bồ Tát Quán Thế Âm cao 67m (tương đương tòa nhà 30 tầng) — pho tượng Phật đứng cao nhất Việt Nam.

Tương truyền vào thời vua Minh Mạng thế kỷ 19, ngư dân bãi cát nơi đây vớt được pho tượng Phật trôi dạt vào bờ, lập am thờ tự và từ đó sóng yên biển lặng, ngư dân ra khơi thuận buồm xuôi gió. Cái tên Bãi Bụt nghĩa là "Cõi Phật giữa trần gian".''',
      storyEn: '''Perched on the lush slopes of the Son Tra Peninsula, Linh Ung Pagoda is revered for its majestic 67-meter Lady Buddha (Guan Yin) statue — the tallest standing Buddha statue in Vietnam.

According to local folklore from the 19th century Nguyen Dynasty, fishermen discovered a sacred Buddha statue washed ashore on this beach. They built a modest shrine, and from that day onward, typhoons calmed and fishermen returned safely. The site was named "Bai But" — Buddha's Haven on Earth.''',
      etiquetteRules: [
        EtiquetteRule(
          icon: '👗',
          titleVi: 'Trang phục che vai & đầu gối',
          titleEn: 'Modest Sacred Dress Code',
          descVi: 'Bắt buộc mặc quần/váy dài qua đầu gối, áo có tay che kín vai khi vào chánh điện.',
          descEn: 'Strictly required: Shoulders and knees must be fully covered inside sacred halls.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '👟',
          titleVi: 'Tháo giày dép & mũ nón',
          titleEn: 'Remove Shoes & Hats',
          descVi: 'Để giày dép đúng nơi quy định ngoài cửa trước khi bước vào Chánh Điện.',
          descEn: 'Take off footwear and headwear before stepping inside the prayer sanctuary.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '🙏',
          titleVi: 'Không quay lưng vào tượng Phật',
          titleEn: 'Respect Sacred Altars',
          descVi: 'Không đứng quay lưng tạo dáng chụp ảnh selfie thiếu tôn trọng trước bàn thờ Phật.',
          descEn: 'Avoid turning your back or posing irreverently in front of sacred Buddha altars.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '🐒',
          titleVi: 'Không cho khỉ hoang ăn',
          titleEn: 'Do Not Feed Wild Primates',
          descVi: 'Bảo vệ tập tính tự nhiên của động vật hoang dã trên Bán đảo Sơn Trà.',
          descEn: 'Preserve the wild instincts of endemic primates on Son Tra Peninsula.',
          isStrict: true,
        ),
      ],
      sdgContribution: 'SDG 10 & 11: Inclusive spiritual space respecting local cultural norms',
      highlights: ['67m Lady Buddha Statue', 'Sacred Main Sanctuary', 'Panoramic Da Nang Bay View'],
    ),

    // 5: Quần thể Thắng cảnh Ngũ Hành Sơn
    5: const HeritageGuide(
      attractionId: 5,
      historicalEra: 'Special National Heritage (Nguyen Dynasty 1825)',
      storyVi: '''Ngũ Hành Sơn gồm 5 ngọn núi đá vôi mang tên theo ngũ hành: Kim, Mộc, Thủy, Hỏa, Thổ. Nơi đây gắn liền với truyền thuyết trứng Rồng Thần thời tiền sử và được vua Minh Mạng đích thân đặt tên vào năm 1825.

Bên trong ngọn Thủy Sơn là Động Huyền Không kỳ vĩ — vòm động thủng tự nhiên đón ánh sáng mặt trời chiếu xuyên qua làn khói trầm hương huyền ảo, từng là nơi đặt tượng Phật Thích Ca và là trạm cứu thương bí mật kiên cường trong chiến tranh.''',
      storyEn: '''The Marble Mountains comprise five limestone karsts named after the five cosmological elements: Metal, Wood, Water, Fire, and Earth. In 1825, Emperor Minh Mang officially designated these peaks.

Inside Thuy Son lies Huyen Khong Cave, an ethereal cavern where natural skylights beam rays of celestial sunlight through fragrant incense smoke, illuminating a stone Buddha carved directly into the cliff wall.''',
      etiquetteRules: [
        EtiquetteRule(
          icon: '👟',
          titleVi: 'Đi giày thể thao chống trơn',
          titleEn: 'Non-Slip Walking Shoes',
          descVi: 'Bậc đá vôi hàng trăm năm tuổi trơn nhẵn và ẩm ướt trong các hang động.',
          descEn: 'Centuries-old stone steps are polished and slippery in humid cave caverns.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '🕯️',
          titleVi: 'Chỉ thắp đúng 1 nén nhang',
          titleEn: 'Light Only 1 Incense Stick',
          descVi: 'Hạn chế khói ngột ngạt và nguy cơ cháy nổ trong không gian kín của hang.',
          descEn: 'Prevents air suffocation and fire hazards inside enclosed subterranean caves.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '🚮',
          titleVi: 'Bảo vệ thạch nhũ tự nhiên',
          titleEn: 'Protect Cave Formations',
          descVi: 'Không khắc vẽ tên lên vách đá và không bẻ thạch nhũ hàng triệu năm.',
          descEn: 'Never carve graffiti or touch fragile stalactites that took millennia to form.',
          isStrict: true,
        ),
      ],
      sdgContribution: 'SDG 11: Protect special national geological landmarks & natural caves',
      highlights: ['Huyen Khong Cave', 'Tam Thai Ancient Pagoda', 'Vong Giang Viewpoint'],
    ),

    // 3: Làng đá Mỹ nghệ Non Nước
    3: const HeritageGuide(
      attractionId: 3,
      historicalEra: 'National Intangible Heritage (Late 17th Century)',
      storyVi: '''Khởi nguồn từ cuối thế kỷ 17 do cụ Huỳnh Bá Quát người Thanh Hóa di cư vào lập nghiệp, Làng đá Non Nước đã gìn giữ nghề điêu khắc đá suốt hơn 300 năm dưới chân núi Ngũ Hành Sơn.

Ngày nay, để bảo vệ nguyên trạng danh thắng Ngũ Hành Sơn, nghệ nhân đã chuyển sang nhập đá cẩm thạch từ các mỏ hợp pháp, kết hợp bàn tay tài hoa chạm khắc tượng nghệ thuật, đồ gia dụng bằng đá vươn tầm xuất khẩu sang hơn 50 quốc gia.''',
      storyEn: '''Founded in the late 17th century by master craftsman Huynh Ba Quat, Non Nuoc Stone Carving Village has preserved its sculpting lineage for over 300 years at the base of the Marble Mountains.

Today, to preserve the natural mountain karsts, artisans ethically source stone from approved quarries, utilizing ancestral chisel techniques to craft fine art sculptures exported worldwide.''',
      etiquetteRules: [
        EtiquetteRule(
          icon: '🛍️',
          titleVi: 'Ủng hộ sản phẩm chính gốc nghệ nhân',
          titleEn: 'Support Verified Local Crafts',
          descVi: 'Mua sắm các tác phẩm đá thủ công có tem nguồn gốc làng nghề thay vì đồ đúc công nghiệp.',
          descEn: 'Purchase authentic handcrafted stone souvenirs to sustain generational artisanal families (SDG 8).',
          isStrict: false,
        ),
        EtiquetteRule(
          icon: '⚠️',
          titleVi: 'Giữ cự ly an toàn khi xem đục đá',
          titleEn: 'Keep Safe Distance in Workshops',
          descVi: 'Đứng cách khu vực nghệ nhân mài và đục đá ít nhất 2 mét để tránh bụi và vụn đá.',
          descEn: 'Stay at least 2 meters away from chiseling stations to protect eyes from stone dust.',
          isStrict: true,
        ),
      ],
      sdgContribution: 'SDG 8: Decent work & preserving traditional artisanal village economies',
      highlights: ['300-Year Stone Sculpting', 'Sandstone Sculptures', 'Master Artisan Workshops'],
    ),

    // 2: Cầu Rồng
    2: const HeritageGuide(
      attractionId: 2,
      historicalEra: 'Da Nang Modern Era (Inaugurated 2013)',
      storyVi: '''Cầu Rồng bắc qua sông Hàn dài 666m, mô phỏng hình tượng con rồng thời Lý dũng mãnh vươn mình ra biển Đông, tượng trưng cho khát vọng cất cánh của thành phố Đà Nẵng thế kỷ 21.

Cầu được trao giải thưởng kỹ thuật kim cương thế giới (EEA) và trở thành biểu tượng du lịch độc nhất khi có thể phun lửa 18 đợt và phun nước 3 đợt vào mỗi 21h00 thứ Bảy và Chủ Nhật.''',
      storyEn: '''Spanning the Han River at 666 meters, Dragon Bridge embodies the heroic Ly Dynasty dragon flying toward the East Sea, symbolizing Da Nang\'s rapid modern economic ascent.

An engineering marvel that won the Diamond Award in Washington DC, the bridge breathes fiery flames and cool water vapor every weekend at 9:00 PM.''',
      etiquetteRules: [
        EtiquetteRule(
          icon: '🔥',
          titleVi: 'Cự ly an toàn khi Rồng phun lửa',
          titleEn: 'Fire Breathing Safety Distance',
          descVi: 'Không chen lấn lên sát đầu Rồng khi phun lửa để tránh hơi nóng và nước tạt.',
          descEn: 'Keep back from the dragon head during fire bursts to avoid intense heat gusts.',
          isStrict: true,
        ),
        EtiquetteRule(
          icon: '🚶',
          titleVi: 'Tuân thủ phân luồng giao thông',
          titleEn: 'Follow Pedestrian Flow',
          descVi: 'Đi trên vỉa hè theo hướng dẫn, sử dụng khuyến nghị phân luồng của SmartTour AI để tránh tắc đường.',
          descEn: 'Stay on designated walkways and use SmartTour AI crowd rerouting to avoid delays.',
          isStrict: true,
        ),
      ],
      sdgContribution: 'SDG 11: Smart pedestrian flow management & urban traffic safety',
      highlights: ['Fire & Water Show (Weekend 9PM)', 'Ly Dynasty Dragon Design', 'Han River Promenade'],
    ),
  };
}

class EtiquetteRule {
  final String icon;
  final String titleVi;
  final String titleEn;
  final String descVi;
  final String descEn;
  final bool isStrict;

  const EtiquetteRule({
    required this.icon,
    required this.titleVi,
    required this.titleEn,
    required this.descVi,
    required this.descEn,
    this.isStrict = false,
  });
}
