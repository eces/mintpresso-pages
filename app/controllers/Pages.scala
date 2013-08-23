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
    println("a")
    Ok(views.html.pages.account())    
  }
  def account_(url: String, path: String) = SignedUrl(url) { implicit request =>
    println("b")
    Ok(views.html.pages.account())    
  }
  def account_usage(url: String) = SignedUrl(url) { implicit request =>
    Ok("HEY")
  }
  def collect(url: String) = TODO
  def order(url: String) = TODO
  def pickup(url: String) = TODO
  def support(url: String) = TODO
}