import gleeunit/should

import geokit/latlng
import geokit/pluscode

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

pub fn test_encode(
  lat lat: Float,
  lng lng: Float,
  length length: Int,
  expected expected_plus_code: String,
) -> Nil {
  let assert Ok(point) = latlng.new(lat:, lng:)
  let assert Ok(code) = pluscode.encode(point: point, length:)

  code
  |> should.equal(expected_plus_code)
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ------------- GOOGLE EXAMPLES - SET 1 --------------
// https://github.com/google/open-location-code/blob/main/test_data/encoding.csv
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

pub fn encode_google_1_1_test() -> Nil {
  test_encode(lat: 20.375, lng: 2.775, length: 6, expected: "7FG49Q00+")
}

pub fn encode_google_1_2_test() -> Nil {
  test_encode(
    lat: 20.3700625,
    lng: 2.7821875,
    length: 10,
    expected: "7FG49QCJ+2V",
  )
}

pub fn encode_google_1_3_test() -> Nil {
  test_encode(
    lat: 20.3701125,
    lng: 2.782234375,
    length: 11,
    expected: "7FG49QCJ+2VX",
  )
}

pub fn encode_google_1_4_test() -> Nil {
  test_encode(
    lat: 20.3701135,
    lng: 2.78223535156,
    length: 13,
    expected: "7FG49QCJ+2VXGJ",
  )
}

pub fn encode_google_1_5_test() -> Nil {
  test_encode(
    lat: 47.0000625,
    lng: 8.0000625,
    length: 10,
    expected: "8FVC2222+22",
  )
}

pub fn encode_google_1_6_test() -> Nil {
  test_encode(
    lat: -41.2730625,
    lng: 174.7859375,
    length: 10,
    expected: "4VCPPQGP+Q9",
  )
}

pub fn encode_google_1_7_test() -> Nil {
  test_encode(lat: 0.5, lng: -179.5, length: 4, expected: "62G20000+")
}

pub fn encode_google_1_8_test() -> Nil {
  test_encode(lat: -89.5, lng: -179.5, length: 4, expected: "22220000+")
}

pub fn encode_google_1_9_test() -> Nil {
  test_encode(lat: 20.5, lng: 2.5, length: 4, expected: "7FG40000+")
}

pub fn encode_google_1_10_test() -> Nil {
  test_encode(
    lat: -89.9999375,
    lng: -179.9999375,
    length: 10,
    expected: "22222222+22",
  )
}

pub fn encode_google_1_11_test() -> Nil {
  test_encode(lat: 0.5, lng: 179.5, length: 4, expected: "6VGX0000+")
}

pub fn encode_google_1_12_test() -> Nil {
  test_encode(lat: 1.0, lng: 1.0, length: 11, expected: "6FH32222+222")
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ------------- SPECIFIC ENCODE EXAMPLES -------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

pub fn encode_brighton_pavilion_gardens_test() -> Nil {
  test_encode(
    lat: 50.822941,
    lng: -0.138397,
    length: 11,
    expected: "9C2XRVF6+5JH",
  )
}

pub fn encode_asheville_pinball_museum_test() -> Nil {
  test_encode(
    lat: 35.596226,
    lng: -82.556625,
    length: 11,
    expected: "867VHCWV+F9R",
  )
}

pub fn encode_hachiko_statue_shibuya_tokyo_test() -> Nil {
  test_encode(
    lat: 35.659056,
    lng: 139.700636,
    length: 11,
    expected: "8Q7XMP52+J7C",
  )
}

pub fn encode_place_de_la_republique_rennes_test() -> Nil {
  test_encode(
    lat: 48.109846,
    lng: -1.679001,
    length: 11,
    expected: "8CWW485C+W9Q",
  )
}
