/// # Plus Codes
/// [plus.codes](https://plus.codes)
///
/// *The algorithm and technology is known as Open Location Code. For all
/// user-facing situations, use 'Plus Codes'.*
///
/// A Plus Code is an alphanumeric string identifying a rectangular
/// cell on the Earth's surface. Longer strings pinpoint smaller cells.
///
/// The code is based on a base20 system with a specific set of characters
/// designed to make it easier to read, speak and prevent objectionable
/// combinations. There is always a plus (+) at a specific part of the
/// code - this differentiates Plus Codes from alphanumeric postal codes
/// and enables shortening.
///
/// This module aims to provide all the functionality outlined in Google's
/// API specification for Open Location Code. It also maintains various
/// conventions outlined in the spec.
///
/// ## Global vs Local
/// Plus Codes can be global or local. A global code can be identified
/// immediately, a local code is more convenient and memorable, but must
/// be paired with a nearby landmark or enclosing village/town/city/etc.
/// to place it.
///
/// ### Example
/// The location is an area by the entrance of Royal Pavilion
/// Gardens, Brighton, United Kingdom.
///
/// - Lat/Long: `50.822510, -0.138142`
/// - Global: `9C2XRVF6+2P5`
/// - Local: `RVF6+2P5 Brighton, United Kingdom`
///
import geokit/latlng.{type LatLng}
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/string

/// Errors returned by [`encode`](#encode), [`decode`](#decode),
/// and [`neighbor`](#neighbor).
pub type PlusCodeError {
  /// The digit length requested for an encode is invalid.
  InvalidCodeLength(length: Int)
  /// [`decode`](#decode) was called with an empty string.
  EmptyString
  /// An invalid character has been passed for decoding.
  InvalidCharacter(char: String, position: Int)
  /// A local Plus Code was passed when a global Plus Code was required.
  GlobalPlusCodeRequired
  /// A global Plus Code was passed with a local Plus Code was required.
  LocalPlusCodeRequired
}

/// A structure that represents the region of a valid global
/// Plus Code.
pub type PlusCodeRegion {
  PlusCodeRegion(sw_corner: LatLng, ne_corner: LatLng, center: LatLng)
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// The characters used to encode lat/long information.
const base20_digits: String = "23456789CFGHJMPQRVWX"

/// The marker character between characters 8 and 10.
const plus: String = "+"

/// When a Plus code is shorter than 8 digits, the end must be
/// padded with 0s to make 8 characters, so there is always a
/// plus anchoring the code.
const padding_char: String = "0"

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// Encodes a LatLng into a global Plus Code whose region encloses it.
///
/// ## Length
/// The digit length of a Plus Code is counted by the
/// number of digits that have location information,
/// not the length of the code itself.
///
/// A Plus Code is 9 characters long minimum, as
/// large area codes get padded with 0s.
///
/// The default length of a Plus Code is 10 digits.
///
/// The only valid lengths of a Plus Code are 2, 4,
/// 6, 8, 10, 11, 12, 13, 14 and 15 digits.
pub fn encode(
  point point: LatLng,
  length length: Int,
) -> Result(String, PlusCodeError) {
  use <- bool.guard(
    when: !global_encoding_digit_length_is_valid(length),
    return: Error(InvalidCodeLength(length: length)),
  )

  let lat = latlng.lat(point)
  let lng = latlng.lng(point)

  let big_digits =
    encode_big_digits(
      lat: { lat +. 90.0 } *. 8000.0
        |> float.truncate,
      lng: { lng +. 180.0 } *. 8000.0
        |> float.truncate,
      // you must do all 5 even if they're sliced off later.
      step: 5,
      acc: [],
    )
    |> list.fold("", string.append)

  let assert Ok(lat_mod) = float.modulo(lat +. 90.0, by: 1.0)
  let assert Ok(lng_mod) = float.modulo(lng +. 180.0, by: 1.0)

  let small_digits =
    encode_small_digits(
      lat: lat_mod *. 2.5e7,
      lng: lng_mod *. 8.192e6,
      step: length - 10,
      acc: [],
    )
    |> list.fold("", string.append)

  // assemble the characters
  let plus_code =
    {
      big_digits
      |> string.slice(at_index: 0, length: int.clamp(length, min: 2, max: 8))
      |> string.pad_end(to: 8, with: padding_char)
    }
    <> plus
    <> {
      big_digits
      |> string.slice(at_index: 7, length: 2)
    }
    <> { small_digits }

  Ok(plus_code)
}

/// Decodes a string representing a full Plus Code into a `PlusCodeRegion`.
pub fn decode(
  global_plus_code: String,
) -> Result(PlusCodeRegion, PlusCodeError) {
  use <- bool.guard(
    when: is_valid_global_plus_code(global_plus_code),
    return: Error(GlobalPlusCodeRequired),
  )
  todo
}

/// Decodes a local Plus Code and returns the nearest matching full Plus Code.
pub fn recover_nearest(
  local_plus_code: String,
  near_latlng: LatLng,
) -> Result(String, PlusCodeError) {
  use <- bool.guard(
    when: is_valid_global_plus_code(local_plus_code),
    return: Error(LocalPlusCodeRequired),
  )
  todo
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// -------------- CONVERSION --------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// Shortens a global Plus Code by 4 characters, to a
/// local Plus Code.
///
/// You can eliminate the first four digits of the code if:
///
/// - The center point of the feature is within 0.4 degrees
/// latitude and 0.4 degrees longitude
/// - The bounding box of the feature is less than 0.8
/// degrees high and wide.
pub fn shorten_by_4(
  global_plus_code global_plus_code: String,
) -> Result(String, PlusCodeError) {
  use <- bool.guard(
    when: is_valid_global_plus_code(global_plus_code),
    return: Error(GlobalPlusCodeRequired),
  )
  global_plus_code
  |> string.drop_end(up_to: 4)
  |> Ok
}

/// Shortens a global Plus Code by 6 charactersm, to a
/// short Plus Code.
pub fn shorten_by_6(
  global_plus_code global_plus_code: String,
) -> Result(String, PlusCodeError) {
  use <- bool.guard(
    when: is_valid_global_plus_code(global_plus_code),
    return: Error(GlobalPlusCodeRequired),
  )
  global_plus_code
  |> string.drop_end(up_to: 6)
  |> Ok
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ------------------- QUERY --------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// Checks if a given string is a valid Plus Code.
///
/// This does not mean that the string can be decoded
/// into `LatLng`, as it may be a local Plus Code instead
/// of a global Plus Code.
pub fn is_valid_plus_code(string: String) -> Bool {
  todo
}

/// Checks if a given string is a valid global Plus Code.
///
/// This does mean that the string can be decoded
/// into `LatLng`.
pub fn is_valid_global_plus_code(string: String) -> Bool {
  todo
}

// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------
// ----------------------------------------------------

/// Checks to see if the desired digit length for
/// encoding (without + or padding) is valid.
fn global_encoding_digit_length_is_valid(len: Int) -> Bool {
  case len {
    2 | 4 | 6 | 8 | 10 | 11 | 12 | 13 | 14 | 15 -> True
    _ -> False
  }
}

/// Encode digits 1-10 in 2 digit chunks.
fn encode_big_digits(
  lat lat: Int,
  lng lng: Int,
  step step: Int,
  acc acc: List(String),
) -> List(String) {
  case step <= 0 {
    True -> acc
    False -> {
      let assert Ok(lat_mod) = int.modulo(lat, by: 20)
      let assert Ok(lng_mod) = int.modulo(lng, by: 20)

      let lat_char = string.slice(base20_digits, lat_mod, 1)
      let lng_char = string.slice(base20_digits, lng_mod, 1)

      encode_big_digits(lat: lat / 20, lng: lng / 20, step: step - 1, acc: [
        lat_char,
        lng_char,
        ..acc
      ])
    }
  }
}

/// Encode digits 11-15, 1 at a time.
fn encode_small_digits(
  lat lat: Float,
  lng lng: Float,
  step step: Int,
  acc acc: List(String),
) -> List(String) {
  case step <= 0 {
    True -> acc
    False -> {
      let assert Ok(mod_lat) = float.modulo(lat, by: 5.0)
      let assert Ok(mod_lng) = float.modulo(lng, by: 4.0)

      let char =
        mod_lat
        |> float.truncate
        |> fn(x) { x * 4 }
        |> fn(x) { x + float.truncate(mod_lng) }
        |> string.slice(base20_digits, _, 1)

      encode_small_digits(
        lat: lat /. 5.0,
        lng: lng /. 4.0,
        step: step - 1,
        acc: [char, ..acc],
      )
    }
  }
}
