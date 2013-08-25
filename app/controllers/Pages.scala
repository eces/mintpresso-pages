package controllers

import play.api._
import play.api.i18n.Messages
import play.api.mvc._
import play.api.data.Forms._
import play.api.data._
import play.api.Play.current
import play.api.libs._
import play.api.cache._
import play.api.libs.json._
import scala.concurrent._
import scala.concurrent.duration._
import play.api.libs.ws.Response
import play.api.libs.concurrent.Execution.Implicits._

object Pages extends Controller with Secured {
  def account(url: String, path: String) = SignedUrl(url) { implicit request =>
    Ok(views.html.pages.account())    
  }
  def accountUsage(url: String) = SignedUrl(url) { implicit request =>
    Ok(Json.obj())
  }
  def accountPlansAndBilling(url: String) = SignedUrl(url) { implicit request =>
    Ok(Json.obj())
  }
  def accountApiKey(url: String) = SignedUrl(url) { implicit request =>
    InternalServerError
    // Ok(Json.obj())
  }
  def collect(url: String, path: String) = TODO
  def order(url: String, path: String) = TODO
  def pickup(url: String, path: String) = TODO
  def support(url: String, path: String) = TODO
}