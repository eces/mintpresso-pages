package models

import play.api.mvc._
import play.api.libs._
import play.api.libs.json._
import play.api.libs.json.Json._
import play.api.libs.concurrent._
import scala.concurrent._
import scala.concurrent.duration._

case class User(no: Long, email: String, name: String, url: String)