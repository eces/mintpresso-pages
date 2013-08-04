import sbt._
import Keys._
import play.Project._

object ApplicationBuild extends Build {

  val appName         = "mintpresso-pages"
  val appVersion      = "1.0-SNAPSHOT"

  val appDependencies = Seq(
    // Add your project dependencies here,
    "com.github.julienrf" %% "play-jsmessages" % "1.5.0",
    "com.typesafe" %% "play-plugins-mailer" % "2.1.0",
    jdbc,
    anorm
  )
  
  val main = play.Project(appName, appVersion, appDependencies).settings(
    resolvers += "julienrf.github.com" at "http://julienrf.github.com/repo/",
    lessEntryPoints := Nil, coffeescriptEntryPoints := Nil, javascriptEntryPoints := Nil
  )

}
