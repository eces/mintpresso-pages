package models

import play.api.mvc._
import play.api.libs.json._
import play.api.i18n.Messages
import play.api.Play.current
import play.api.Logger
import play.api.libs._
import play.api.libs.concurrent.Execution.Implicits._
import scala.concurrent._
import scala.concurrent.duration._
import java.util.Date

case class Key(var id: String, var no: Long, var url: List[String], 
  var address: List[String], 
  var scope: List[String], 
  var logThreshold: String = "info",
  var createdAt: Date = new Date , var updatedAt: Date = new Date ) {

  def toJson: JsObject = {
    Json.obj(
      "$id" ->        this.id,
      "$no" ->        this.no,
      "url" ->        this.url,
      "address" ->    this.address,
      "scope" ->      this.scope,
      "logThreshold"-> this.logThreshold,
      "$createdAt"  -> this.createdAt,
      "$updatedAt"  -> this.updatedAt
    )
  }

  def toTypedJson: JsObject = {
    Json.obj(
      "key" -> this.toJson
    )
  }
}

object Key {

  def apply(json: JsValue): Key = {
    val key = (json \ "key").as[JsObject]
    Key(
      (key \ "$id").as[String],
      (key \ "$no").as[Long],
      (key \ "url").as[List[String]],
      (key \ "address").as[List[String]],
      (key \ "scope").as[List[String]],
      (key \ "logThreshold").as[String],
      (key \ "$createdAt").asOpt[Date].getOrElse( new Date ),
      (key \ "$updatedAt").asOpt[Date].getOrElse( new Date )
    )
  }

}