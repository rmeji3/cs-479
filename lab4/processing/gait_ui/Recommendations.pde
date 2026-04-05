class Recommendation {
  String title;
  ArrayList<String> shoes;
  ArrayList<String> shoeImages; // Image URLs for shoes
  ArrayList<String> exercises;
  String tip;
  
  Recommendation(String title, ArrayList<String> shoes, ArrayList<String> shoeImages, ArrayList<String> exercises, String tip) {
    this.title = title;
    this.shoes = shoes;
    this.shoeImages = shoeImages;
    this.exercises = exercises;
    this.tip = tip;
  }
}

class RecommendationEngine {
  HashMap<String, Recommendation> recommendations;
  String currentGaitType = "Normal";
  
  RecommendationEngine() {
    recommendations = new HashMap<String, Recommendation>();
    initializeDatabase();
  }
  
  void initializeDatabase() {
    // Heel Striker Recommendations
    ArrayList<String> heelShoes = new ArrayList<String>();
    heelShoes.add("Nike Air Max (Extra cushioning)");
    heelShoes.add("Brooks Glycerin (Soft padding)");
    heelShoes.add("ASICS Gel Kayano (Support)");
    heelShoes.add("New Balance 990v5 (Stability)");
    heelShoes.add("Hoka One One (Max cushion)");
    
    ArrayList<String> heelImages = new ArrayList<String>();
    heelImages.add("shoe_images/nike_airmax.jpg");
    heelImages.add("shoe_images/brooks_glycerin.jpg");
    heelImages.add("shoe_images/ASICS_gelkayano.jpg");
    heelImages.add("shoe_images/newbalance_990v5.jpg");
    heelImages.add("shoe_images/hoka_oneone.jpg");
    
    ArrayList<String> heelExercises = new ArrayList<String>();
    heelExercises.add("Calf stretches (reduce impact)");
    heelExercises.add("Hamstring strengthening");
    heelExercises.add("Glute activation exercises");
    
    Recommendation heelStrike = new Recommendation(
      "Heel Striker",
      heelShoes,
      heelImages,
      heelExercises,
      "High heel impact detected. Focus on calf flexibility to improve stride."
    );
    recommendations.put("HEEL_STRIKER", heelStrike);
    
    // Forefoot Striker Recommendations
    ArrayList<String> foreShoes = new ArrayList<String>();
    foreShoes.add("Nike Zoom Fly (Responsive)");
    foreShoes.add("ASICS Metaracer (Lightweight)");
    foreShoes.add("Saucony Endorphin Speed (Minimal drop)");
    foreShoes.add("Adidas Adizero Boston (Racing flat)");
    foreShoes.add("New Balance Fuelcell (Energy return)");
    
    ArrayList<String> foreImages = new ArrayList<String>();
    foreImages.add("shoe_images/nike_zoomfly.jpg");
    foreImages.add("shoe_images/ASICS_metaracer.jpg");
    foreImages.add("shoe_images/saucony_endorphinspeed.jpg");
    foreImages.add("shoe_images/adidas_adizeroboston.jpg");
    foreImages.add("shoe_images/newbalance_fuelcell.jpg");
    
    ArrayList<String> foreExercises = new ArrayList<String>();
    foreExercises.add("Calf strengthening (handle load)");
    foreExercises.add("Plantar fascia mobility");
    foreExercises.add("Ankle stability work");
    
    Recommendation foreStrike = new Recommendation(
      "Forefoot Striker",
      foreShoes,
      foreImages,
      foreExercises,
      "High forefoot pressure detected. Ensure adequate calf strength and recovery."
    );
    recommendations.put("FOREFOOT_STRIKER", foreStrike);
    
    // Overpronator Recommendations
    ArrayList<String> pronaShoes = new ArrayList<String>();
    pronaShoes.add("Nike Vomero (Stability)");
    pronaShoes.add("Brooks Adrenaline GTS (Motion control)");
    pronaShoes.add("ASICS GT-2000 (Structured support)");
    pronaShoes.add("New Balance 860v11 (Pronation support)");
    pronaShoes.add("Saucony Guide (Guidance system)");
    
    ArrayList<String> pronaImages = new ArrayList<String>();
    pronaImages.add("shoe_images/nike_vomero.jpg");
    pronaImages.add("shoe_images/brooks_adrenalineGTS.jpg");
    pronaImages.add("shoe_images/ASICS_GT2000.jpg");
    pronaImages.add("shoe_images/newbalance_860v11.jpg");
    pronaImages.add("shoe_images/saucony_guide.jpg");
    
    ArrayList<String> pronaExercises = new ArrayList<String>();
    pronaExercises.add("Hip abductor strengthening");
    pronaExercises.add("Single-leg balance exercises");
    pronaExercises.add("Arch activation exercises");
    
    Recommendation overpronator = new Recommendation(
      "Overpronator",
      pronaShoes,
      pronaImages,
      pronaExercises,
      "Uneven lateral/medial pressure detected. Strengthen hip and arch stability."
    );
    recommendations.put("OVERPRONATOR", overpronator);
    
    // Normal Gait Recommendations
    ArrayList<String> normalShoes = new ArrayList<String>();
    normalShoes.add("Nike Pegasus (Versatile)");
    normalShoes.add("ASICS Gel-Contend (Balanced)");
    normalShoes.add("Brooks Ghost (Neutral comfort)");
    normalShoes.add("New Balance 680 (Daily wear)");
    normalShoes.add("Saucony Ride (Smooth ride)");
    
    ArrayList<String> normalImages = new ArrayList<String>();
    normalImages.add("shoe_images/nike_pegasus.jpg");
    normalImages.add("shoe_images/ASICS_gelcontend.jpg");
    normalImages.add("shoe_images/brooks_ghost.jpg");
    normalImages.add("shoe_images/newbalance_680.jpg");
    normalImages.add("shoe_images/saucony_ride.jpg");
    
    ArrayList<String> normalExercises = new ArrayList<String>();
    normalExercises.add("Regular strength training");
    normalExercises.add("Flexibility and mobility work");
    normalExercises.add("Cross-training activities");
    
    Recommendation normal = new Recommendation(
      "Normal Gait",
      normalShoes,
      normalImages,
      normalExercises,
      "Balanced gait detected. Maintain current routine with regular stretching."
    );
    recommendations.put("NORMAL", normal);
  }
  
  void analyzeGait(float[] fsrs, float mfp) {
    // fsrs = {MF, LF, MM, HEEL}
    float mf = fsrs[0];
    float lf = fsrs[1];
    float mm = fsrs[2];
    float heel = fsrs[3];
    
    float totalForefoot = mf + lf;
    float totalMidfoot = mm;
    float totalPressure = mf + lf + mm + heel;
    
    if (totalPressure < 50) {
      currentGaitType = "NORMAL";
      return;
    }
    
    // Classify gait pattern
    float heelPercentage = (heel / totalPressure) * 100;
    float forePercentage = (totalForefoot / totalPressure) * 100;
    float mfpDifference = abs(mf - lf); // Medial vs Lateral imbalance
    
    // Check for overpronation (significant lateral/medial imbalance)
    if (mfpDifference > (totalPressure * 0.4)) {
      currentGaitType = "OVERPRONATOR";
    }
    // Check for heel striker (high heel pressure)
    else if (heelPercentage > 50 && forePercentage < 30) {
      currentGaitType = "HEEL_STRIKER";
    }
    // Check for forefoot striker (high forefoot, low heel)
    else if (forePercentage > 60 && heelPercentage < 20) {
      currentGaitType = "FOREFOOT_STRIKER";
    }
    // Normal gait
    else {
      currentGaitType = "NORMAL";
    }
  }
  
  String getGaitType() {
    return currentGaitType;
  }
  
  Recommendation getRecommendation() {
    Recommendation rec = recommendations.get(currentGaitType);
    return rec != null ? rec : recommendations.get("NORMAL");
  }
}
