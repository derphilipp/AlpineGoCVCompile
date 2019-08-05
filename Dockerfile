FROM golang:1.12-alpine3.10

ENV OPENCV_VERSION=4.1.0

ENV BUILD="alpine-sdk \
         build-base \
         ca-certificates \
         g++ \
         gcc \
         git \
         gst-plugins-base \
         gstreamer \
         jasper-libs \
         libavc1394 \
         libc-dev \
         libgphoto2 \
         libjpeg-turbo \
         libpng \
         libwebp \
         libwebp-dev \
         linux-headers \
         make \
         musl-dev \
         openblas \
         tiff"

ENV DEV="clang \
        clang-dev \
        cmake \
        gst-plugins-base-dev  \
        gstreamer-dev \
        jasper-dev \
        libavc1394-dev \
        libgphoto2-dev \
        libjpeg-turbo-dev \
        libpng-dev  \
        openblas-dev \
        pkgconf \
        tiff-dev"

RUN apk update && \
    apk add --no-cache ${BUILD} ${DEV}

RUN mkdir /tmp/opencv && \
    cd /tmp/opencv && \
    wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip opencv.zip && \
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip opencv_contrib.zip && \
    mkdir /tmp/opencv/opencv-${OPENCV_VERSION}/build && cd /tmp/opencv/opencv-${OPENCV_VERSION}/build && \
    cmake \
    -D BUILD_ANDROID_EXAMPLES=NO \
    -D BUILD_DOCS=NO \
    -D BUILD_EXAMPLES=NO \
    -D BUILD_PERF_TESTS=NO \
    -D BUILD_TESTS=NO \
    -D BUILD_opencv_java=NO \
    -D BUILD_opencv_python2=NO \
    -D BUILD_opencv_python3=NO \
    -D BUILD_opencv_python=NO \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D INSTALL_C_EXAMPLES=NO \
    -D INSTALL_PYTHON_EXAMPLES=NO \
    -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv/opencv_contrib-${OPENCV_VERSION}/modules \
    -D OPENCV_GENERATE_PKGCONFIG=YES \
    -D WITH_FFMPEG=YES \
    .. && \
    make -j8 && \
    make install && \
    cd && rm -rf /tmp/opencv

RUN apk del ${DEV} && \
    rm -rf /var/cache/apk/*

ENV PKG_CONFIG_PATH /usr/local/lib64/pkgconfig
ENV LD_LIBRARY_PATH /usr/local/lib64
ENV CGO_CPPFLAGS -I/usr/local/include
ENV CGO_CXXFLAGS "--std=c++1z"
ENV CGO_LDFLAGS "-L/usr/local/lib -lopencv_core -lopencv_face -lopencv_videoio -lopencv_imgproc -lopencv_highgui -lopencv_imgcodecs -lopencv_objdetect -lopencv_features2d -lopencv_video -lopencv_dnn -lopencv_xfeatures2d -lopencv_plot -lopencv_tracking"


RUN go get -u -d gocv.io/x/gocv
RUN cd /go/src/gocv.io/x/gocv && make deps
RUN cd /go/src/gocv.io/x/gocv && go run ./cmd/version/main.go

RUN mkdir /app

ENTRYPOINT /bin/sh
